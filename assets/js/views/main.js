import knayi from 'knayi-myscript'

export default class MainView {
  mount() {
    // This will be executed when the document loads...
    console.log('MainView mounted')
    // console.log(knayi.fontDetect('မဂၤလာပါ'))
    $(document).ready(function() {
      // Assign global variable to support functions
      var global = (1,eval)('this')
      init_custom_actions()

    });
  }

  unmount() {
    // This will be executed when the document unloads...
    console.log('MainView unmounted')
  }
}

/* ------------- GLOBAL METHODS  --------------------------------------------------- */
  global.validateMyanmarMobileNumber = (str) => {
      return /^([09]{1})([0-9]{10})$/.test(str)
  }
  global.validateEmail = (str) => {
    var re = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
    return re.test(str);
  }
  global.validatePrice = (str) => {
      return /^([1-9]{1})([0-9]{1,9})?$/.test(str)
  }

  global.scrollToAnchor = (aid) => {
    // var aTag = $("a[name='"+ aid +"']");
    var aTag = $("[name='"+ aid +"']");
    $('html,body').animate({scrollTop: aTag.offset().top},'slow');
  }

/* ------------- DOCUMENT LOAD  --------------------------------------------------- */
  let init_custom_actions = () => {

    /* ------------- BOOSTRAP CUSTO  --------------------------------------------------- */
    // Correct behaviour on the multiselect items
    $('.submenu-item-hover').on('click', function(event) {
      $(this).mouseenter()
      event.stopPropagation()
    })

    /* ------------- GENERAL DISPLAY --------------------------------------------------- */
    // Remove flashes after click
    $('.alert').on('click', function () {
      $(this).alert('close')
    })
    // Set up CustomScroller - http://manos.malihu.gr/jquery-custom-content-scroller/
    // $("#sidebar").mCustomScrollbar({
    //   theme: "minimal"
    // });
    // Opens the slidebar
    $('#sidebarCollapse').on('click', function () {
        $('.collapse-level1').collapse('hide')
        $('.collapse-level2').collapse('hide')
        $("#searchBar").collapse('hide')
        $(".category-selector").addClass('d-none')
        $('#navbarDismiss').show()
        $('#sidebar').addClass('active')
        $('.overlay').addClass('active')
        $('.collapse.in').toggleClass('in')
        $('a[aria-expanded=true]').attr('aria-expanded', 'false')
    })
    // Close the sidebar
    $('#navbarDismiss, .overlay').on('click', function () {
        $('#sidebar').removeClass('active')
        $('.overlay').removeClass('active')
        $('#navbarDismiss').hide()
        $('.collapse-slide').collapse('hide')
        $('#searchBar').collapse('hide')
    })
    // Manage slidebar collapses
    $('.collapse-level1').on('show.bs.collapse', function (e) {
      $('.collapse-level1').collapse('hide')
      $('.collapse-level2').collapse('hide')
    })
    $('.collapse-level2').on('show.bs.collapse', function (e) {
      e.stopPropagation()
      $('.collapse-level2').collapse('hide')
    })

    /* ------------- HEADER SEARCHES --------------------------------------------------- */
    // Trigger search row in the header
    $('.family-selector').on('click', function () {
      var family_id = $(this).attr('data-target')
      $(".category-selector").not(`#searchFamily_${family_id}`).addClass('d-none')
      $(".triangle").not(`#triangle_${family_id}`).addClass('d-none')
      $(`#searchFamily_${family_id}`).toggleClass("d-none")
      $(`#triangle_${family_id}`).toggleClass("d-none")
    })
    // Close the search row when something else is clicked
    $('#main').on('click', function () {
      $("#searchBar").collapse('hide')
      $(".category-selector").addClass('d-none')
      $(".triangle").addClass('d-none')
    })
    // Reinit the searchbar when it is collapsed
    $('#searchBar').on('hidden.bs.collapse', function (e) {
      $(".category-selector").addClass('d-none')
      $(".triangle").addClass('d-none')
    })

  /* ------------- OFFERS DISPLAY  --------------------------------------------------- */
    load_actions_in_offers_display_page()
    // Button see more offers
    $('#btn-more-offers').on('click', function() {
      event.preventDefault()
      event.stopPropagation()
      var cursor_after = $('#config').attr('data-cursor-after')
      var search_params = JSON.parse($('#config').attr('data-search-params'))
      console.log(search_params)
      call_internal_api("/api/add_offers", "get_more_offers", {cursor_after: cursor_after, search_params: search_params})
    })

    /* ------------- OFFERS FORM  --------------------------------------------------- */
    // Set up the lightbox - http://ashleydw.github.io/lightbox/#no-wrapping
    $(document).on('click', '[data-toggle="lightbox"]', function(event) {
        event.preventDefault()
        $(this).ekkoLightbox()
    });
    // Click on number OK or press enter after filling phone number field
    $('#btn_validate_number').on('click', function (e) {
      event.preventDefault()
      event.stopPropagation()
      var phone_number = $("#announce_phone_number").val()
      call_internal_api("/api/phone", "get_phone_details", phone_number)
    })
    // Click on change number
    $('#btn_change_number').on('click', function (e) {
      event.preventDefault()
      event.stopPropagation()
      reset_announce_form_field()
    })
    // Click on unlink viber number
    // $('#btn_unlink_number').on('click', function (e) {
    //   event.preventDefault()
    //   event.stopPropagation()
    //   var phone_number = $("#announce_phone_number").val()
    //   call_internal_api("/api/phone", "unlink_viber", phone_number)
    // })
    // Currency selector
    $('.ddown_change_currency').on('click', function() {
      $('#choosen_currency_text')[0].innerHTML = this.innerHTML
      $('#announce_currency').val(this.innerHTML)
    })
    // Checks the email field
    $('#announce_email').on('change', function() {
      var email = $(this).val()
      if (validateEmail(email) == false) {
        console.log("wrong email")
        $(this).val('').focus()
      }
    })
    // Get the title and check if it looks like Zawgyi
    $('#announce_title').on('change', function() {
      var title = $(this).val()
      if (knayi.fontDetect(title) == "zawgyi") {
        console.log("zawgyi detected")
        $('#announce_zawgyi').val('true')
      } else {
        console.log("unicode detected")
        $('#announce_zawgyi').val('false')
      }
    })
    // Makes sure to get rounded prices only
    $('#announce_price').on('change', function() {
      var price = $(this).val()
      var rounded_price = Math.round(price)
      if(isNaN(rounded_price)) {
        rounded_price = "";
      }
      $(this).val(rounded_price).focus()
    })
  }

  /* ------------- METHODS  --------------------------------------------------- */
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
      $(this).closest('div.offer-actions').addClass('d-none').next('div.offer-contact').removeClass('d-none')
    })
    // Hide the sellor's number
    $('.btn-see-number').on('click', function() {
      $(this).closest('div.offer-contact').addClass('d-none').prev('div.offer-actions').removeClass('d-none')
    })
    // Send an alert on the offer
    $('.btn-offer-alert').on('click', function() {
      var offer_id = $(this).attr('data-offer-id')
      call_internal_api("/api/alert", "alert_on_offer", offer_id)
      // $(this).closest('div.offer-actions').addClass('d-none').next('div.offer-contact').removeClass('d-none')
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
    $('.btn-copy-number').on('click', function() {
      var phone_number = $(this).attr('data-phone-number')
      var $temp = $("<input>")
      $("body").append($temp)
      $temp.val(phone_number).select()
      document.execCommand("copy")
      $temp.remove()
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

  // Empty form when the phone_number is not accepted
  let reset_announce_form_field = () => {
    // console.log("wrong phone number : form reseted")
    $('.collapsible_form').collapse('hide')
    $('#announce_phone_number').removeAttr('disabled')
    $('#btn_validate_number').show()
    $('#btn_change_number').hide()
    $('#phone_helper').show()
    $('#announce_phone_number').val('').focus()//.removeClass("field-success").addClass("field-danger")
    $('#announce_user_id').val('')
    $('#announce_nickname').val('')
    $('#announce_email').val('')
  }
  // Populate form when the phone_number is accepted
  let validate_phone_number_pop_field = (user) => {
    $('#announce_phone_number').attr('disabled', 'disabled')  //.removeClass("field-danger").addClass("field-success")
    $('#btn_validate_number').hide()
    $('#btn_change_number').removeClass('d-none').show()
    $('#phone_helper').hide()
    $('#announce_user_id').val(user.id)
    $('#announce_nickname').val(user.nickname).focus()
    $('#announce_email').val(user.email)
    if (user.viber_active == true) {
      $('#field-viber').show()
      $('#btn-viber').hide()
    } else {
      $('#field-viber').hide()
      $('#btn-viber').show()
    }
    $('.collapsible_form').collapse('show')
  }

  // Disable an alert button after getting back a response
  let disable_alert_button = (offer_id) => {
    $(`#btn_alert_${offer_id}`).addClass("disabled").removeClass('btn-offer-alert')
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

  // Call internal phone API to check phone number
  let call_internal_api = (url, scope, params) => {
    if (scope == "get_more_offers"){
      $("#btn-more-offers").addClass("d-none")
      $("#btn-more-offers-wait").removeClass("d-none")
    }
    var token = $('#config').attr('data-api')
    fetch(url, {
      headers: {
        "accept": "application/json",
        "content-type": "application/json",
        "Authorization": token,
      },
      method: "POST",
      body: JSON.stringify({scope: scope, params: params})
    })
    .then(function(response) {
      if (response.status !== 200) {
        console.log('There was on API problem. Status Code: ' + response.status);
        // console.log(response)
        $("#btn-more-offers-wait").addClass("d-none")
        $("#btn-more-offers").removeClass("d-none")
        return;
      }
      // Examine the text in the response
      response.json().then(function(response) {
        if ('results' in response) {
          console.log(response)
          var scope = response.results.scope
          var data = response.results.data
          var error = response.results.error
          if (scope == "get_phone_details") {
            if ('user' in data) {
              console.log("received phone details")
              validate_phone_number_pop_field(data.user)
            } else {
              console.log(error)
              reset_announce_form_field()
            }
          } else if (scope == "get_more_offers"){
            console.log("received new offers to show")
            add_new_offers_to_page(data.offers, data.new_cursor_after)
          } else if (scope == "alert_on_offer"){
            if ('offer_id' in data) {
              console.log("alert posted on offer")
              disable_alert_button(data.offer_id)
            } else {
              console.log(error)
            }
          } else {
          console.log("API response not understood")
          }
        } else {
          console.log("Problem in Json response")
        }
      })
    })
    .catch(function(err) {
      console.log('Fetch Error :-S', err);
    })
  }
