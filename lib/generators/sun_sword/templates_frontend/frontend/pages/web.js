import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    connect() {
        this.sidebarEl  = document.querySelector(".sidebar")
        this.backdropEl = document.querySelector(".backdrop-active")
        this.toggleBtns = document.querySelectorAll("[data-action~='web#sidebarToggle']")
        if (!this.sidebarEl || !this.backdropEl) return

        this.isOpen = false
        this.prefersReduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches
        this._onEsc = (e) => { if (e.key === "Escape") this.sidebarClose() }

        this.backdropEl.addEventListener("click", () => this.sidebarClose(), { passive: true })

        // Inisialisasi: pastikan posisi tertutup
        this.sidebarEl.classList.add("-translate-x-full")
        this.sidebarEl.classList.remove("translate-x-0")
        this._setBackdrop(false)
    }

    // === Sidebar ===
    sidebarToggle(e) {
        e?.preventDefault()
        this.isOpen ? this.sidebarClose() : this.sidebarOpen(e?.currentTarget)
    }

    sidebarOpen(triggerEl) {
        if (this.isOpen) return
        this.isOpen = true

        // Kurangi jank: pastikan element “on GPU”
        this.sidebarEl.style.transform = "translate3d(-100%,0,0)"
        // Force reflow → lalu transisi ke posisi buka pada frame berikut
        requestAnimationFrame(() => {
            this.sidebarEl.classList.remove("-translate-x-full")
            this.sidebarEl.classList.add("translate-x-0")
            this.sidebarEl.style.transform = "" // kembalikan, biar Tailwind kelas yang mengatur
        })

        this._setBackdrop(true)
        document.documentElement.classList.add("overflow-hidden")
        triggerEl?.setAttribute("aria-expanded", "true")
        this.sidebarEl.setAttribute("aria-hidden", "false")
        document.addEventListener("keydown", this._onEsc, { passive: true })

        // Fokus pertama
        this.sidebarEl.querySelector("a, button, input, [tabindex]")
            ?.focus({ preventScroll: true })
    }

    sidebarClose() {
        if (!this.isOpen) return
        this.isOpen = false

        // Transisi balik (geser keluar)
        this.sidebarEl.classList.add("-translate-x-full")
        this.sidebarEl.classList.remove("translate-x-0")

        this._setBackdrop(false)
        document.documentElement.classList.remove("overflow-hidden")
        this.sidebarEl.setAttribute("aria-hidden", "true")
        this.toggleBtns.forEach((btn) => btn.setAttribute("aria-expanded", "false"))
        document.removeEventListener("keydown", this._onEsc)
        this.toggleBtns[0]?.focus({ preventScroll: true })
    }

    onSidebarClick(event) {
        const a = event.target.closest("a, button[type='submit']")
        if (!a) return
        setTimeout(() => this.sidebarClose(), 0)
    }

    // === Util ===
    _setBackdrop(show) {
        // Jika user minta “reduce motion”, skip animasi
        if (this.prefersReduced) {
            this.backdropEl.classList.toggle("hidden", !show)
            this.backdropEl.classList.toggle("pointer-events-none", !show)
            this.backdropEl.style.opacity = show ? "1" : "0"
            return
        }

        // Pastikan elemen ada di flow saat mulai animasi
        this.backdropEl.classList.remove("hidden")
        requestAnimationFrame(() => {
            if (show) {
                this.backdropEl.classList.remove("opacity-0", "pointer-events-none")
                this.backdropEl.classList.add("opacity-100")
            } else {
                // Fade out, lalu sembunyikan setelah selesai
                this.backdropEl.classList.remove("opacity-100")
                this.backdropEl.classList.add("opacity-0", "pointer-events-none")
                const onEnd = () => {
                    this.backdropEl.classList.add("hidden")
                    this.backdropEl.removeEventListener("transitionend", onEnd)
                }
                this.backdropEl.addEventListener("transitionend", onEnd)
            }
        })
    }
    confirmationDestroy(event) {
        const chooseTypes = document.querySelectorAll(".confirmation-destroy-" + event.params.id);
        chooseTypes.forEach((element) => {
            element.classList.remove('hidden');
        })
    }

    confirmationDestroyCancel(event) {
        const chooseTypes = document.querySelectorAll(".confirmation-destroy-" + event.params.id);
        chooseTypes.forEach((element) => {
            element.classList.add('hidden');
        })
    }
    // Opsional: submenu & profil tetap bisa dipakai dari versi sebelumnya
    profileSetting(event) {
        const container = event.currentTarget.closest("li")
        const dropdown = container?.querySelector("[class^='profile-']")
        if (!dropdown) return

        dropdown.classList.toggle("hidden")
        const closeOnOutside = (e) => {
            if (!dropdown.contains(e.target) && !event.currentTarget.contains(e.target)) {
                dropdown.classList.add("hidden")
                window.removeEventListener("click", closeOnOutside, true)
            }
        }
        window.addEventListener("click", closeOnOutside, true)
    }
}
