// import knayi from 'knayi-myscript'

export default class MainView {
  mount() {
    // This will be executed when the document loads...
    console.log('MainView mounted')
    // console.log(knayi.fontDetect('မဂၤလာပါ'))
    $(document).ready(function() {
      // Assign global variable to support functions
      var global = (1,eval)('this')
      init_custom_actions()
      load_boostrap_carousel()
    });
  }

  unmount() {
    // This will be executed when the document unloads...
    console.log('MainView unmounted')
  }
}

/* ------------- GLOBAL METHODS  --------------------------------------------------- */
// global.validateMyanmarMobileNumber = (str) => {
//     return /^([09]{1})([0-9]{10})$/.test(str)
// }
// global.validateEmail = (str) => {
//   var re = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
//   return re.test(str);
// }
// global.validatePrice = (str) => {
//     return /^([1-9]{1})([0-9]{1,9})?$/.test(str)
// }

global.clipboard = require('clipboard-polyfill');
global.bodyScrollLock = require('body-scroll-lock'); // Block scrolling when modal is showed

global.scrollToAnchor = (aid) => {
  // var aTag = $("a[name='"+ aid +"']");
  var aTag = $("[name='"+ aid +"']");
  $('html,body').animate({scrollTop: aTag.offset().top},'slow');
}

// Call internal user API
global.call_internal_api = (url, scope, params) => {
  var token = $('#config').attr('data-api')
  return fetch(url, {
    headers: {"accept": "application/json", "content-type": "application/json", "Authorization": token},
    method: "POST",
    body: JSON.stringify({scope: scope, params: params})
  })
  .then((response) => {
     if(response.status !== 200) {
       console.log('There was on API problem. Status Code: ' + response.status)
     } else {
       return response.json()
     }
  })
  .then((json) => {
    if ('results' in json) {
      return json
    } else {
      console.log("Problem in Json response")
    }
  })
  .catch(function(err) {
    console.log('Fetch Error :-S', err);
  })
}

// Boostrap 4 caroussel select active and swipe
global.load_boostrap_carousel = () => {
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

/* ------------- METHODS  --------------------------------------------------- */
let init_custom_actions = () => {

  /* ------------- BOOSTRAP CUSTO  --------------------------------------------------- */
  // Correct behaviour on the multiselect items
  $('.submenu-item-hover').on('click', function(event) {
    $(this).mouseenter()
    event.stopPropagation()
  })

  /* ------------- CHROME ANDROID FIX  --------------------------------------------------- */
  // see https://css-tricks.com/the-trick-to-viewport-units-on-mobile/
  let vh = window.innerHeight * 0.01;
  document.documentElement.style.setProperty('--vh', `${vh}px`);
  // Removed to avoid the resizing effect on scroll
  // window.addEventListener('resize', () => {
  //   let vh = window.innerHeight * 0.01;
  //   document.documentElement.style.setProperty('--vh', `${vh}px`);
  // });

  /* ------------- GENERAL DISPLAY --------------------------------------------------- */
  // Remove flashes after click
  $('.alert').on('click', function () {
    $(this).alert('close')
  })
  // Activate Boostrap plugins
  $('[data-toggle="popover"]').popover()
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
      // bodyScrollLock.disableBodyScroll($("#sidebar"))
      bodyScrollLock.disableBodyScroll(
        $($("#sidebar")), {
          allowTouchMove: el => {
            while (el && el !== document.body) {
              if (el.getAttribute('body-scroll-lock-ignore') !== null) {
                return true
              }
              el = el.parentNode
            }
          }
        }
      )
  })
  // Closes the sidebar
  $('#navbarDismiss, .overlay').on('click', function () {
      $('.collapse-level1').collapse('hide')
      $('.collapse-level2').collapse('hide')
      $('#sidebar').removeClass('active')
      $('.overlay').removeClass('active')
      $('#navbarDismiss').hide()
      $('.collapse-slide').collapse('hide')
      $('#searchBar').collapse('hide')
      bodyScrollLock.clearAllBodyScrollLocks()
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

}
