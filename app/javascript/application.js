import "@hotwired/turbo-rails"

document.addEventListener("turbo:submit-start", (event) => {
  const button = event.target.querySelector("button[aria-label='Upvote'], button[aria-label='Downvote']")
  if (button) button.disabled = true
})
