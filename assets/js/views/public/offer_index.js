import MainView from '../main'

export default class View extends MainView {
  mount() {
    super.mount()
    console.log("Offer index mounted")
    init_functions()
    load_actions_in_offers_display_page()
  }

  unmount() {
    super.unmount()
    console.log('Offer index unmounted')
  }
}

// ------------- METHODS  -----------------------------------------------------------------
let init_functions = () => {
  // Button see more offers
  $('#btn-more-offers').on('click', function() {
    event.preventDefault()
    event.stopPropagation()
    $(this).addClass("d-none")
    $("#btn-more-offers-wait").removeClass("d-none")
    var cursor_after = $('#config').attr('data-cursor-after')
    var search_params = JSON.parse($('#config').attr('data-search-params'))
    call_internal_api("/api/add_offers", "get_more_offers", {cursor_after: cursor_after, search_params: search_params}).then(function (response) {
      var data = response.results.data
      console.log("received new offers to show")
      add_new_offers_to_page(data.offers_map, data.new_cursor_after)
    })
  })
}

// Add new offers received by the button load more
let add_new_offers_to_page = (offers_map, new_cursor_after) => {
  // var new_cursor_after = new_cursor_after
  $('#config').attr('data-cursor-after', new_cursor_after)
  if (new_cursor_after == null) {
    $("#btn-more-offers-wait").addClass("d-none")
  } else {
    $("#btn-more-offers-wait").addClass("d-none")
    $("#btn-more-offers").removeClass("d-none")
  }
  // Append the offers_html to the page
  $("#offers-results").append(offers_map.inline_html)
  // Reload the JS functions on the new DOM
  load_actions_in_offers_display_page()
}

// Disable an alert button after getting back a response
let disable_alert_button = (offer_id) => {
  $(`#btn_alert_${offer_id}`).addClass("disabled").removeClass('btn-offer-alert')
}

// Load the actions on offers display page
let load_actions_in_offers_display_page = () => {
  // Boostrap 4 caroussel select active and swipe
  load_boostrap_carousel()
  // Disable the scrolling behind modal
  // $('.modal').on('show.bs.modal', function () {
  //   bodyScrollLock.disableBodyScroll($(this))
  // })
  // $('.modal').on('hide.bs.modal', function () {
  //   bodyScrollLock.clearAllBodyScrollLocks()
  // })
  // Display big announce on small announce click
  $('.btn-small-announce').on('click', function() {
    $(".btn-small-announce").removeClass('d-none')
    $(".big-announce").addClass('d-none')
    var announce_id = $(this).attr('data-announce-id')
    $(`#small_announce_${announce_id}`).addClass('d-none')
    $(`#big_announce_${announce_id}`).removeClass('d-none')
    scrollToAnchor(`big_announce_${announce_id}`)
  })
  // Show the sellor's number
  $('.btn-show-contact').on('click', function() {
    var offer_id = $(this).attr('data-offer-id')
    $(this).removeClass('btn-show-number') // We can click only 1 time
    $(`#footer_btn_${offer_id}`).addClass('d-none')
    $(`#footer_contact_${offer_id}`).removeClass('d-none')
    if (offer_id != undefined) {
      call_internal_api("/api/count_clic", "count_clic_number", offer_id).then(function (response) {
        var data = response.results.data
        if ('offer_id' in data) {
          // console.log("clic posted on offer")
        } else {
          console.log(error)
        }
      })
    }
  })
  // Send an alert on the offer
  $('.btn-offer-alert').on('click', function() {
    var offer_id = $(this).attr('data-offer-id')
    $(this).removeAttr('data-offer-id')
    if (offer_id != undefined) {
      call_internal_api("/api/alert", "alert_on_offer", offer_id).then(function (response) {
        var data = response.results.data
        if ('offer_id' in data) {
          console.log("alert posted on offer")
          disable_alert_button(data.offer_id)
        } else {
          console.log(error)
        }
      })
    }
  })

  // Copy phone number to clipboard
  $('button.copy-number').on('click', function() {
    var number = $(this).attr('data-phone-number')
    clipboard.writeText(number);
  })
}
