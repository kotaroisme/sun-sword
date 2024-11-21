import {Controller} from "@hotwired/stimulus"
import anime from "animejs";

export default class extends Controller {
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

    profileSetting(event) {
        console.log('Profile');
        const profileSettingBrowser = document.querySelector(".profile-browser");
        const profileSettingMobile = document.querySelector(".profile-mobile");
        if (profileSettingBrowser.classList.contains('hidden')) {
            profileSettingBrowser.classList.remove('hidden');
            console.log('show');
        } else {
            console.log('hide');
            profileSettingBrowser.classList.add('hidden');
        }
        if (profileSettingMobile.classList.contains('hidden')) {
            profileSettingMobile.classList.remove('hidden');
            console.log('show');
        } else {
            console.log('hide');
            profileSettingMobile.classList.add('hidden');
        }
    }

    sidebarToggle(event) {
        const backdropActive = document.querySelector(".backdrop-active");
        const sidebar = document.querySelector(".sidebar");
        if (sidebar.classList.contains('side_hide')) {
            sidebar.classList.remove('side_hide');
            backdropActive.classList.remove('hidden');
            anime({
                targets: ".backdrop-active",
                translateX: 0,
                opacity: [0, 0.8],
                easing: 'easeInOutSine',
                complete: function (anim) {
                    console.log('Backdrop Active');
                }
            })
            anime({
                targets: '.sidebar',
                translateX: 300,
                duration: 1000,
                easing: 'easeInOutExpo',
                complete: function (anim) {
                    console.log('Sidebar show!');
                }
            });
        } else {
            sidebar.classList.add('side_hide');
            anime({
                targets: '.sidebar',
                easing: 'easeInOutExpo',
                translateX: -300,
                duration: 1000,
                complete: function (anim) {
                    console.log('Sidebar Close!');
                }
            });
            anime({
                targets: ".backdrop-active",
                translateX: 0,
                opacity: [0.8, 0],
                easing: 'easeInOutSine',
                complete: function (anim) {
                    backdropActive.classList.add('hidden');
                }
            })
        }
    }

    onSidebarClick(event) {
        event.preventDefault()
        const url = event.target.href;
        const backdropActive = document.querySelector(".backdrop-active");
        const sidebar = document.querySelector(".sidebar");
        if (url !== undefined) {
            sidebar.classList.add('side_hide');
            anime({
                targets: '.sidebar',
                easing: 'easeInOutExpo',
                translateX: -300,
                duration: 1000,
                complete: function (anim) {
                    console.log('Sidebar Close!');
                }
            });
            anime({
                targets: ".backdrop-active",
                translateX: 0,
                opacity: [0.6, 0],
                easing: 'easeInOutSine',
                complete: function (anim) {
                    console.log('opacity');
                    backdropActive.classList.add('hidden');
                    Turbo.visit(url);
                }
            })
        }
    }
}

