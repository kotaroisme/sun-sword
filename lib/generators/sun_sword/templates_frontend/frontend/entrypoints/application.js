// LOAD everything
import "@hotwired/turbo-rails"
import {stimulus} from "./stimulus"

import WebController from "../pages/web"
import TestsStimulusController from "../pages/tests-stimulus.js"

import "../stylesheets/application.css"
console.log("Kotaro is here")
console.log(window.location.hash.slice(1))

const textElement = document.getElementById(window.location.hash.slice(1))
if(textElement !== null){
    textElement.scrollIntoView({behavior: "smooth"})
}
stimulus.register("web", WebController)
stimulus.register("tests-stimulus", TestsStimulusController)
