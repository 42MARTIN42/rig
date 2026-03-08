import { Header } from "/libs/pluck/ui/js/core/header.js";
import { Footer } from "/libs/pluck/ui/js/core/footer.js";

let loading_screen = null;

class LoadScreen {
    constructor(data) {
        this.data = data;
        this.images = data.background_images;
        this.image_index = 0;
        this.main_container = $("#loadscreen");
        this.bg1 = $("#bg1");
        this.bg2 = $("#bg2");
        this.play_enabled = false;
        this.news = data.news || [];
        this.keybinds = data.keybinds || [];
        this.gallery_images = data.gallery_images || [];
        this.init();
    }

    async init() {
        this.bg1.css("background-image", `url(${this.images[this.image_index]})`);
        this.bg1.css("opacity", "1");

        this.build();
        this.start_background_cycle();
    }
    
    set_background_image(image) {
        this.bg1.css("background-image", `url(${image})`);
        this.bg2.css("background-image", `url(${image})`);
    }

    update_background_image() {
        const current_bg = this.bg1.css("opacity") === "1" ? this.bg1 : this.bg2;
        const next_bg = this.bg1.css("opacity") === "1" ? this.bg2 : this.bg1;
        this.image_index = (this.image_index + 1) % this.images.length;
        next_bg.css("background-image", `url(${this.images[this.image_index]})`);
        current_bg.css("opacity", "0");
        next_bg.css("opacity", "1");
    }

    start_background_cycle() {
        setInterval(() => this.update_background_image(), 6000);
    }

    build_news_entries() {
        return this.news.map(item => `
            <div class="info_entry">
                <span class="info_date">${item.date}</span>
                <span class="info_text">${item.text}</span>
            </div>
        `).join("");
    }

    build_keybinds() {
        return this.keybinds.map(item => `
            <div class="keybind_entry">
                <span class="keybind_key">${item.key}</span>
                <span class="keybind_label">${item.label}</span>
            </div>
        `).join("");
    }

    build() {
        const header = new Header({
            elements: {
                left: [
                    { type: "logo", image: this.data.logo },
                    { type: "text", title: this.data.header, subtitle: this.data.span }
                ]
            }
        });

        const footer = new Footer({
            elements: {
                left: [
                    { type: "audioplayer", autoplay: this.data.auto_play_music, randomize: this.data.play_random_song }
                ],
                right: [
                    { type: "actions", actions: [
                        { 
                            key: "P", 
                            label: "Play", 
                            class: "disabled",
                            id: "btn_play",
                            action: () => { 
                                $.post(`https://rig/loadscreen:play`, JSON.stringify({})); 
                            } 
                        },
                        { 
                            key: "ESCAPE", 
                            label: "Disconnect", 
                            action: () => {
                                $.post(`https://rig/loadscreen:disconnect`, JSON.stringify({}));
                            }, 
                            id: "btn_disconnect" 
                        }
                    ]}
                ]
            }
        });

        const layout = `
            <div class="loadscreen_container">
                <div class="vignette"></div>
                ${header.get_html()}
                <div class="loadscreen_content">
                    <div class="loadscreen_left">
                        <div class="loadscreen_section news_section">
                            <h3 class="section_title">NEWS & UPDATES</h3>
                            <div class="info_entries">
                                ${this.build_news_entries()}
                            </div>
                        </div>
                        <div class="loadscreen_section controls_section">
                            <h3 class="section_title">CONTROLS</h3>
                            <div class="keybinds_list">
                                ${this.build_keybinds()}
                            </div>
                        </div>
                        <div class="loadscreen_section gallery_section">
                            <h3 class="section_title">GALLERY</h3>
                            <div class="gallery_container">
                                <img id="gallery_image" src="${this.gallery_images[0] || 'https://placehold.co/400x300'}" alt="Gallery" class="gallery_image">
                                <div class="gallery_controls">
                                    <button id="gallery_prev" class="gallery_btn">&lt;</button>
                                    <span id="gallery_counter">1 / ${this.gallery_images.length}</span>
                                    <button id="gallery_next" class="gallery_btn">&gt;</button>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                ${footer.get_html()}
            </div>
        `;

        this.main_container.append(layout);
        footer.bind_events();

        let gallery_index = 0;
        const gallery_images = this.gallery_images;
        const update_gallery = () => {
            $("#gallery_image").attr("src", gallery_images[gallery_index]);
            $("#gallery_counter").text(`${gallery_index + 1} / ${gallery_images.length}`);
        };

        $("#gallery_next").on("click", () => {
            gallery_index = (gallery_index + 1) % gallery_images.length;
            update_gallery();
        });

        $("#gallery_prev").on("click", () => {
            gallery_index = (gallery_index - 1 + gallery_images.length) % gallery_images.length;
            update_gallery();
        });
    }
}

window.addEventListener("mousemove", function(e) {
    const cursor = document.getElementById("cursor");
    if (cursor) {
        cursor.style.left = e.clientX + "px";
        cursor.style.top = e.clientY + "px";
    }
});

window.addEventListener("message", (event) => {
    if (event.data?.action === "load_complete") {
        $("#btn_play").removeClass("disabled");
    }
});

$(document).ready(async function () {
    const data = {
        logo: "/ui/loadscreen/assets/logo.png",
        header: "RIG",
        span: "Survival Framework (pre-alpha v0.0.1)",
        auto_play_music: true,
        play_random_song: true,
        news: [
            { date: "12/06", text: "Server is now live!" },
            { date: "12/05", text: "Alpha testing has begun" },
            { date: "12/01", text: "Survival features implemented" }
        ],
        keybinds: [
            { key: "I", label: "Inventory" },
            { key: "TAB", label: "Action Menu" },
            { key: "1", label: "Primary Weapon" },
            { key: "2", label: "Secondary Weapon" },
            { key: "3", label: "Tertiary Weapon" },
            { key: "4", label: "Melee Weapon" }
        ],
        background_images: [ 
            "/ui/loadscreen/assets/backgrounds/sv_bg_1.jpg",
            "/ui/loadscreen/assets/backgrounds/sv_bg_2.jpg",
            "/ui/loadscreen/assets/backgrounds/sv_bg_3.jpg"
        ],
        gallery_images: [
            "/ui/loadscreen/assets/gallery/sv_gal_1.jpg",
            "/ui/loadscreen/assets/gallery/sv_gal_2.jpg",
            "/ui/loadscreen/assets/gallery/sv_gal_3.jpg"
        ]
    };

    loading_screen = new LoadScreen(data);
});