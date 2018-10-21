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
    var cursor_after = $('#config').attr('data-cursor-after')
    var search_params = JSON.parse($('#config').attr('data-search-params'))
    call_internal_api("/api/add_offers", "get_more_offers", {cursor_after: cursor_after, search_params: search_params}).then(function (response) {
      var data = response.results.data
      console.log("received new offers to show")
      add_new_offers_to_page(data.offers, data.new_cursor_after)
    })
  })
}

// Add new offers received by the button load more
let add_new_offers_to_page = (offers, new_cursor_after) => {
  var new_cursor_after = new_cursor_after
  $('#config').attr('data-cursor-after', new_cursor_after)
  if (new_cursor_after == null) {
    $("#btn-more-offers-wait").addClass("d-none")
  } else {
    $("#btn-more-offers-wait").addClass("d-none")
    $("#btn-more-offers").removeClass("d-none")
  }
  for (const offer of offers) {
    var small = offer.display_small
    $("#offers-results").append(small)
    var big = offer.display_big
    $("#offers-results").append(big)
  }
  // Reload the JS functions on the new DOM
  load_actions_in_offers_display_page()
}

// Disable an alert button after getting back a response
let disable_alert_button = (offer_id) => {
  $(`#btn_alert_${offer_id}`).addClass("disabled").removeClass('btn-offer-alert')
}

// Load the actions on offers display page
let load_actions_in_offers_display_page = () => {
  // Display big announce on small announce click
  $('.btn-small-announce').on('click', function() {
    $(".btn-small-announce").removeClass('d-none')
    $(".big-announce").addClass('d-none')
    var announce_id = $(this).attr('data-announce-id')
    $(`#small_announce_${announce_id}`).addClass('d-none')
    $(`#big_announce_${announce_id}`).removeClass('d-none')
    scrollToAnchor(`big_announce_${announce_id}`)
  })
  // Close big announce on close btn click
  $('.btn-close').on('click', function() {
    var announce_id = $(this).attr('data-announce-id')
    $(`#big_announce_${announce_id}`).addClass('d-none')
    $(`#small_announce_${announce_id}`).removeClass('d-none')
    scrollToAnchor(`small_announce_${announce_id}`)
  })
  // Closes the offer display on close btn click
  $('.btn-close').on('click', function() {
    var announce_id = $(this).attr('data-announce-id')
    $(`#small_announce_${announce_id}`).removeClass('d-none')
    $(`#big_announce_${announce_id}`).addClass('d-none')
    scrollToAnchor(`small_announce_${announce_id}`)
  })
  // Show the sellor's number
  $('.btn-show-number').on('click', function() {
    $(this).closest('div.offer-actions').addClass('d-none')
    var offer_id = $(this).attr('data-offer-id')
    $(this).removeAttr('data-offer-id') // We can click only 1 time
    $(`#offer_contact_${offer_id}`).removeClass('d-none')
    if (offer_id != undefined) {
      call_internal_api("/api/count_clic", "count_clic_number", offer_id).then(function (response) {
        var data = response.results.data
        if ('offer_id' in data) {
          console.log("clic posted on offer")
        } else {
          console.log(error)
        }
      })
    }
  })
  // Hide the sellor's number
  $('.btn-see-number').on('click', function() {
    $(this).closest('div.offer-contact').addClass('d-none').prev('div.offer-actions').removeClass('d-none')
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
  // Keep the offer in likes cookie
  $('.btn-offer-like').on('click', function() {
    var offer_id = $(this).attr('data-offer-id')
    if (document.cookie.indexOf('likes') == -1 ) { // Cookie doesnt exist yet
      var arr = new Array(0)
      var cookie = JSON.stringify(arr)
    } else { // Cookie exist already
      var cookie = document.cookie.replace(/(?:(?:^|.*;\s*)likes\s*\=\s*([^;]*).*$)|^.*$/, "$1")
    }
    var likes = JSON.parse(cookie)
    console.log(likes)
    if (likes.includes(offer_id)){} else {
      likes.push(offer_id)
      document.cookie = "likes=" + JSON.stringify(likes)
    }
  })
  // Copy phone number to clipboard
  $('.copy-number').on('click', function() {
    var phone_number = $(this).attr('data-phone-number')
    var $temp = $("<input>")
    $("body").append($temp)
    $temp.val(phone_number).select()
    document.execCommand("copy")
    $temp.remove()
    $(".btn-copy-number").removeClass('show')
    $(this).find('.btn-copy-number').addClass('show')
  })
  // Boostrap 4 caroussel select active and swipe
  $('.carousel-inner').each(function(){
    $(this).children(":first").addClass('active');
  })
  $('.carousel-indicators').each(function(){
    $(this).children(":first").addClass('active');
  })
  $('.carousel').carousel({interval: false})
  $(".carousel-inner").swipe({
    swipeLeft:function(event, direction, distance, duration, fingerCount) {
        $(this).parent().carousel('next')
    },
    swipeRight: function() {
        $(this).parent().carousel('prev')
    },
    threshold:75
  })
}
