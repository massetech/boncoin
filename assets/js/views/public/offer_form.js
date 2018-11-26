import MainView from '../main'

export default class View extends MainView {
  mount() {
    super.mount()
    console.log("Offer form mounted")
    init_functions()
  }

  unmount() {
    super.unmount()
    console.log('Offer form unmounted')
  }
}

// ------------- METHODS  -----------------------------------------------------------------
let init_functions = () => {
  // Set up the lightbox - http://ashleydw.github.io/lightbox/#no-wrapping
  $(document).on('click', '[data-toggle="lightbox"]', function(event) {
      event.preventDefault()
      $(this).ekkoLightbox()
  })

  $('#btn_validate_number').on('click', function (e) {
    event.preventDefault()
    event.stopPropagation()
    var phone_number = $("#user_phone_number").val()
    call_internal_api("/api/phone", "get_phone_details", phone_number).then(function (response) {
      // console.log(response)
      var data = response.results.data
      var error = response.results.error
      if ('user' in data) {
        validate_phone_number_pop_field(response.results.data.user)
      } else {
        console.log(error)
        reset_announce_form_field()
      }
    })
  })

  // Click on change number
  $('#btn_change_number').on('click', function (e) {
    event.preventDefault()
    event.stopPropagation()
    reset_announce_form_field()
  })
  $('#gift-btn').on('click', function () {
    $('#user_announces_0_price').val("0")
    $('#ddown-currency-kyats').trigger('click');
  })
  // Currency selector
  $('.ddown_change_currency').on('click', function() {
    $('#choosen_currency_text')[0].innerHTML = this.innerHTML
    $('#announce_currency').val(this.innerHTML)
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
  // $('#announce_price').on('change', function() {
  //   var price = $(this).val()
  //   var rounded_price = Math.round(price)
  //   if(isNaN(rounded_price)) {
  //     rounded_price = "";
  //   }
  //   $(this).val(rounded_price).focus()
  // })
}

// Empty form when the phone_number is not accepted
let reset_announce_form_field = () => {
  // console.log("wrong phone number : form reseted")
  $('.collapsible_form_bot').collapse('hide')
  $('.collapsible_form_offer').collapse('hide')
  $('#user_phone_number').removeAttr('readonly')
  $('#btn_validate_number').show()
  $('#btn_change_number').hide()
  $('#phone_helper').show()
  $('#user_phone_number').val('').focus()
  $('#user_nickname').val('')
}

// Populate form when the phone_number is accepted
let validate_phone_number_pop_field = (user) => {
  $('#user_phone_number').attr('readonly', 'readonly')  //.removeClass("field-danger").addClass("field-success")
  $('#btn_validate_number').hide()
  $('#btn_change_number').removeClass('d-none').show()
  $('#phone_helper').hide()
  $('#announce_user_id').val(user.id)
  $('#user_nickname').val(user.nickname).focus()
  $('#user_viber_number').val(user.viber_number)
  // Select bot buttons to be shown
  if (user.bot_active == true) {
    $('#field-bot').show()
    $('#btn-bot').hide()
    if (user.bot_provider == "viber") {
      $('#viber-linked').show()
      $('#messenger-linked').hide()
    } else {
      $('#viber-linked').hide()
      $('#messenger-linked').show()
    }
    $('.collapsible_form_offer').collapse('show')
  } else {
    // No bot connected yet to this user
    $('#field-bot').hide()
    $('#btn-bot').show()
  }
  $('.collapsible_form_bot').collapse('show')
}
