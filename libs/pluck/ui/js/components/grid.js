/*
--------------------------------------------------

This file is part of PLUCK.
You are free to use these files within your own resources.
Please retain the original credit and attached MIT license.
Support honest development.

Author: Case @ BOII Development
License: https://github.com/boiidevelopment/pluck/blob/main/LICENSE
GitHub: https://github.com/boiidevelopment/pluck

--------------------------------------------------
*/

import { resolve_image_path } from "./../utils.js";

export class Grid {
    /**
     * @param {Object} config
     * @param {string} [config.title=""]
     * @param {Object} [config.layout={}]
     * @param {number} [config.columns=10]
     * @param {number} [config.rows=6]
     * @param {Function|null} [config.on_move=null]
     * @param {string|null} [config.section_key=null]
     * @param {Array<Object>} [config.items=[]]
     * @param {boolean} [config.draggable=true]
     */
    constructor({ title = "", layout = {}, on_move = null, section_key = null, items = [], draggable = true } = {}) {
        this.title = title;
        this.layout = layout;
        this.columns = Number(layout.columns ?? 10);
        this.rows = Number(layout.rows ?? 6);
        this.cell_size = layout.cell_size || "64px";
        this.scroll_y = layout.scroll_y === "none" ? "scroll_y_none" : layout.scroll_y === "auto" ? "scroll_y_auto" : "scroll_y_on";
        this.scroll_x = layout.scroll_x === "none" ? "scroll_x_none" : layout.scroll_x === "auto" ? "scroll_x_auto" : "scroll_x_on";
        this.on_move = on_move;
        this.section_key = section_key;
        this.items = items;
        this.draggable = draggable;
        this.container_selector = null;
        this._$container = null;
    }

    _grid_style() {
        return `grid-template-columns: repeat(${this.columns}, ${this.cell_size}); grid-template-rows: repeat(${this.rows}, ${this.cell_size});`;
    }

    get_html() {
        const cells_html = this.get_cells_html();
        const items_html = this.items.map(item => this.create_item(item)).join("");
        const grid_style = this._grid_style();
        return `<div class="grid_cells" style="${grid_style}">${cells_html}</div><div class="grid_items" style="${grid_style}">${items_html}</div>`;
    }

    get_cells_html() {
        const total = this.columns * this.rows;
        return Array(total).fill(null).map((_, i) => {
            const col = (i % this.columns) + 1;
            const row = Math.floor(i / this.columns) + 1;
            return `<div class="grid_cell"
                         data-col="${col}"
                         data-row="${row}"
                         data-section-key="${this.section_key}">
                    </div>`;
        }).join("");
    }

    create_item(item) {
        if (!item || !item.id) return "";

        const col = item.col || 1;
        const row = item.row || 1;
        const w = item.w || 1;
        const h = item.h || 1;
        const category = item.category?.toLowerCase() || "uncategorized";
        const rarity = item.on_hover?.rarity?.toLowerCase() || "common";
        const dataset_attrs = item.dataset ? Object.entries(item.dataset).map(([k, v]) => `data-${k}="${v}"`).join(" ") : "";
        const tooltip_data = item.on_hover ? `data-tooltip='${JSON.stringify({ on_hover: item.on_hover }).replace(/'/g, "&apos;").replace(/"/g, "&quot;")}'` : "";
        const img = item.image ? `<div class="grid_item_image"><img src="${resolve_image_path(item.image, "/core/pluck/ui/assets/items/")}" /></div>` : "";
        const quantity = item.quantity > 1 ? `<div class="grid_item_quantity">${item.quantity}</div>` : "";
        const progress = (item.progress?.value ?? -1) >= 0 ? `<div class="grid_item_progress"><div class="grid_item_progress_fill" style="width:${Math.min(100, Math.max(0, item.progress.value))}%"></div></div>` : "";
        const footer = quantity || progress ? `<div class="grid_item_footer">${progress}</div>` : "";
        const label = item.label ? `<div class="grid_item_label">${item.label}</div>` : "";

        return `
            <div class="grid_item rarity_${rarity}"
                 style="grid-column: ${col} / span ${w}; grid-row: ${row} / span ${h};"
                 data-item-id="${item.id}"
                 data-col="${col}"
                 data-row="${row}"
                 data-w="${w}"
                 data-h="${h}"
                 data-section-key="${this.section_key}"
                 data-category="${category}"
                 ${dataset_attrs}
                 ${tooltip_data}>
                ${img}${label}${quantity}${footer}
            </div>
        `.trim();
    }

    render_to(selector) {
        const $target = typeof selector === "string" ? $(selector) : $(selector);
        if ($target.length === 0) return;

        const w = `calc(${this.columns} * ${this.cell_size})`;
        const h = `calc(${this.rows} * ${this.cell_size})`;

        $target.addClass(`${this.scroll_x} ${this.scroll_y}`).attr("data-columns", this.columns).attr("data-rows", this.rows).attr("data-section-key", this.section_key).css({ width: w, height: h }).html(this.get_html());

        this.container_selector = typeof selector === "string" ? selector : null;
        this._$container = $target;
        this._init_drag_and_drop();
        window.ui_instance?.tooltip?.bind_tooltips();
    }

    _init_drag_and_drop() {
        if (!this.draggable) return;

        const $container = this._$container;
        const ns = `griddrag_${this.section_key}`;
        Grid._drag ??= null;
        Grid._ghost ??= null;
        Grid._global_bound ??= false;

        const cleanup = () => {
            Grid._drag = null;
            if (Grid._ghost) {
                Grid._ghost.remove();
                Grid._ghost = null;
            }
            $(".grid_item_dragging").removeClass("grid_item_dragging");
            $(".grid_cell_drop_target").removeClass("grid_cell_drop_target");
            window.ui_instance?.tooltip?.hide?.();
        };

        const get_cell_at = (x, y) => {

            const layers = document.querySelectorAll(".grid_items");
            layers.forEach(l => (l.style.pointerEvents = "none"));

            const under = document.elementFromPoint(x, y);

            layers.forEach(l => (l.style.pointerEvents = ""));

            if (!under) return null;
            const cell = under.closest(".grid_cell");
            if (!cell) return null;

            return {
                col: parseInt(cell.dataset.col),
                row: parseInt(cell.dataset.row),
                section: cell.dataset.sectionKey
            };
        };

        const highlight_cells = (col, row, w, h, section_key) => {
            $(".grid_cell_drop_target").removeClass("grid_cell_drop_target");

            const $target_container = $(`[data-section-key="${section_key}"]`).filter(function () {
                return $(this).find(".grid_cells").length > 0 || $(this).hasClass("grid_cells");
            });

            const $cells_layer = $(`[data-section-key="${section_key}"] .grid_cells`);
            for (let c = col; c < col + w; c++) {
                for (let r = row; r < row + h; r++) {
                    $cells_layer.find(`.grid_cell[data-col="${c}"][data-row="${r}"]`).addClass("grid_cell_drop_target");
                }
            }
        };

        if (!Grid._global_bound) {
            Grid._global_bound = true;

            $(document).on("pointermove.griddrag_global", (e) => {
                if (!Grid._drag || !Grid._ghost) return;
                Grid._ghost.css({ left: e.clientX + 8, top: e.clientY + 8 });
                const cell = get_cell_at(e.clientX, e.clientY);
                if (cell) highlight_cells(cell.col, cell.row, Grid._drag.w, Grid._drag.h, cell.section);
            });

            $(document).on("pointerup.griddrag_global pointercancel.griddrag_global", async (e) => {
                if (!Grid._drag) return;
                const d = Grid._drag;
                const cell = get_cell_at(e.clientX, e.clientY);

                if (!cell) {
                    cleanup();
                    return;
                }

                if (d.from_section === cell.section && d.from_col === cell.col && d.from_row === cell.row) {
                    cleanup();
                    return;
                }

                if (typeof d.on_move === "function") {
                    await d.on_move(
                        String(d.item_id),
                        String(d.from_col),
                        String(d.from_row),
                        String(cell.col),
                        String(cell.row),
                        String(d.from_section),
                        String(cell.section),
                        d.dataset
                    );
                }

                cleanup();
            });
        }

        $container.off(`pointerdown.${ns}`);
        $container.on(`pointerdown.${ns}`, ".grid_item", (e) => {
            const $item = $(e.currentTarget);

            const item_id = $item.attr("data-item-id");
            const from_col = parseInt($item.attr("data-col"));
            const from_row = parseInt($item.attr("data-row"));
            const w = parseInt($item.attr("data-w"));
            const h = parseInt($item.attr("data-h"));
            const from_section = $item.attr("data-section-key");

            if (!item_id || !from_section) return;

            const dataset = {};
            Object.entries(e.currentTarget.dataset).forEach(([k, v]) => { dataset[k] = v; });

            Grid._drag = { item_id, from_col, from_row, w, h, from_section, on_move: this.on_move, dataset };

            e.currentTarget.classList.add("grid_item_dragging");

            Grid._ghost?.remove();
            Grid._ghost = $item.clone();
            Grid._ghost.css({
                position: "fixed",
                left: e.clientX + 8,
                top: e.clientY + 8,
                pointerEvents: "none",
                zIndex: 999999,
                width: $item.outerWidth(),
                height: $item.outerHeight(),
                opacity: 0.85
            });
            $("body").append(Grid._ghost);

            e.preventDefault();
        });
    }

    update_items(new_items) {
        this.items = new_items || [];
        const $target = this._$container || (this.container_selector ? $(this.container_selector) : null);
        if (!$target || !$target.length) return;

        $target.html(this.get_html());
        this._init_drag_and_drop();
        window.ui_instance?.tooltip?.bind_tooltips();
    }
}