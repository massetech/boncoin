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

    // Remove flashes after click
    $('.alert').on('click', function () {
      $(this).alert('close')
    })

    // HEADER
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

    // SLIDEBAR
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

    // Manage conditions collapses
    $('.collapse').on('show.bs.collapse', function (e) {
      $('.collapse').collapse('hide')
    })

    // Manage about collapses
    $('#about').on('show.bs.collapse', function (e) {
      $('.collapse').collapse('hide')
    })

    // Set up the lightbox - http://ashleydw.github.io/lightbox/#no-wrapping
    $(document).on('click', '[data-toggle="lightbox"]', function(event) {
        event.preventDefault();
        $(this).ekkoLightbox();
    });

    // Correct behaviour on the multiselect items
    $('.submenu-item-hover').on('click', function(event) {
      $(this).mouseenter()
      event.stopPropagation()
    })

    // Click on the see number
    $('.btn-show-number').on('click', function() {
      var announce_id = $(this).attr('data-announce-id')
      var phone_number = $(this).attr('data-phone-number')
      $(this).addClass('d-none')
      $(`#number_${announce_id}`).removeClass('d-none')

      var $temp = $("<input>")
      $("body").append($temp)
      $temp.val(phone_number).select()
      document.execCommand("copy")
      $temp.remove()
    })

    // Click on a small announce
    $('.btn-small-announce').on('click', function() {
      $(".small-announce").removeClass('d-none')
      $(".big-announce").addClass('d-none')
      var announce_id = $(this).attr('data-announce-id')
      $(`#small_announce_${announce_id}`).addClass('d-none')
      $(`#big_announce_${announce_id}`).removeClass('d-none')
      scrollToAnchor(`big_announce_${announce_id}`)
    })

    // Click on a big announce
    $('.btn-big-announce').on('click', function() {
      var announce_id = $(this).attr('data-announce-id')
      $(`#small_announce_${announce_id}`).removeClass('d-none')
      $(`#big_announce_${announce_id}`).addClass('d-none')
      scrollToAnchor(`small_announce_${announce_id}`)
    })

    // Click on number OK or press enter
    $('#btn_check_number').on('click', function (e) {
      event.preventDefault();
      event.stopPropagation()
      var phone_number = $("#announce_phone_number").val()
      call_phone_api(phone_number, "get_phone_details")
    })

    // Click on unlink viber number
    $('#btn_unlink_number').on('click', function (e) {
      event.preventDefault();
      event.stopPropagation()
      var phone_number = $("#announce_phone_number").val()
      call_phone_api(phone_number, "unlink_viber")
    })

    // Boostrap 4 caroussel 1st elements active selection
    $('.carousel-inner').each(function(){
      $(this).children(":first").addClass('active');
    })
    $('.carousel-indicators').each(function(){
      $(this).children(":first").addClass('active');
    })
    $('.carousel').carousel({interval: false})
    $(".carousel-inner").swipe({
      swipeLeft:function(event, direction, distance, duration, fingerCount) {
          $(this).parent().carousel('next');
      },
      swipeRight: function() {
          $(this).parent().carousel('prev');
      },
      threshold:75
    })

    // Currency selector
    $('.ddown_change_currency').on('click', function() {
      // console.log(this.innerHTML)
      $('#choosen_currency_text')[0].innerHTML = this.innerHTML
      $('#announce_currency').val(this.innerHTML)
    })

    // Get the title and check if it looks like Zawgyi
    $('#announce_email').on('change', function() {
      var email = $(this).val()
      if (validateEmail(email) == false) {
        console.log("wrong email")
        $(this).val('').focus()
      }
    })

    // Blocked by the not building library
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

    $('#announce_price').on('change', function() {
      var price = $(this).val()
      var rounded_price = Math.round(price)
      if(isNaN(rounded_price)) {
        rounded_price = "";
      }
      $(this).val(rounded_price).focus()
    })
  }

  /* ------------- OFFERS FORM  --------------------------------------------------- */

  // Empty form when the phone_number is not accepted
  let reset_announce_form_field = () => {
    // console.log("wrong phone number : form reseted")
    $('.collapsible_form').collapse('hide')
    $('#announce_phone_number').val('').focus().removeClass("field-success").addClass("field-danger")
    $('#announce_user_id').val('')
    $('#announce_nickname').val('')
    $('#announce_email').val('')
  }
  // Populate form when the phone_number is accepted
  let validate_phone_number_pop_field = (user_id, nickname, email, viber, nb_announces) => {
    // console.log("Good phone number : form processed with pop")
    $('#announce_phone_number').removeClass("field-danger").addClass("field-success")
    $('#announce_user_id').val(user_id)
    $('#announce_nickname').val(nickname).focus()
    $('#announce_email').val(email)
    // if (password == "") {$('#field-password').hide()}
    // else {$('#field-password').show()}
    if (viber == true) {
      $('#field-viber').show()
      $('#btn-viber').hide()
      if (nb_announces > 0) {
        $('#btn_unlink_number').attr('disabled','disabled')
      }
      else {
        $('#btn_unlink_number').removeAttr('disabled')
      }
    } else {
      $('#field-viber').hide()
      $('#btn-viber').show()
    }
    $('.collapsible_form').collapse('show')
  }

  // Call internal API to check phone number
  let call_phone_api = (phone_number, scope) => {
    var token = $('#config').attr('data-phone')
    fetch("/api/phone", {
      headers: {
        "accept": "application/json",
        "content-type": "application/json",
        "Authorization": 'Bearer ' + token,
      },
      method: "POST",
      body: JSON.stringify({phone_number: phone_number, scope: scope})
    })
    .then(function(response) {
      if (response.status !== 200) {
        console.log('There was on API problem. Status Code: ' + response.status);
        return;
      }
      // Examine the text in the response
      response.json().then(function(response) {
        if ('data' in response) {
          var data = response.data
          if (data.scope == "get_phone_details") {
            console.log("received phone details")
            validate_phone_number_pop_field(data.user_id, data.user_nickname, data.email, data.viber_active, data.nb_announces)
          } else if (data.scope == "unlink_viber"){
            console.log("phone number unlinked with Viber")
            remove_viber_btn_after_unlink()
          } else {
            console.log("API response not understood")
          }
        } else {
          reset_announce_form_field()
        }
      });
    })
    .catch(function(err) {
      console.log('Fetch Error :-S', err);
    })
  }

  // Call internal API to unlink Viber
  let remove_viber_btn_after_unlink = () => {
    $('#field-viber').hide()
    $('#btn-viber').show()
  }
