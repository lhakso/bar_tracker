function toggleForm(button) {
    // Find the closest `.occupancy-form` element from the clicked button
    const form = button.closest('.bar-tile').querySelector('.occupancy-form');
    if (form) {
        form.classList.toggle('hidden');
    }
}
