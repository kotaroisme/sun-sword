import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
    static targets = ['count', 'display']
    static values = {
        count: { type: Number, default: 0 }
    }

    connect() {
        console.log('Counter controller connected')
        this.updateDisplay()
    }

    increment() {
        this.countValue++
        this.updateDisplay()
    }

    decrement() {
        this.countValue--
        this.updateDisplay()
    }

    updateDisplay() {
        this.displayTarget.textContent = this.countValue
    }

    countValueChanged() {
        console.log('Count changed to:', this.countValue)
    }
}