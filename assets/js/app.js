import "phoenix_html";
// import socket from "./socket"

// Import CSS
import "../css/app.scss";
// Import static images
function requireAll(r) { r.keys().forEach(r); }
requireAll(require.context('../static/images/', true, /\.(png|gif|svg|jpg|jpeg)$/));

import '../node_modules/bootstrap';                   // imports Boostrap js functions
import '../node_modules/jquery-touchswipe';           // imports touchswipe effects
import '../node_modules/ekko-lightbox';
import "../vendor/bootstrap-select-1.13.0-beta/js/bootstrap-select";
import "../vendor/slim/js/slim.kickstart.min";
// import "../vendor/custom_scroller/jquery.mCustomScrollbar.concat.min";


import loadView from './views/loader';          // Custom js to run code per page
window.__socket = require("phoenix").Socket;    // Fix for webpack with drab
window.clipboard = require('clipboard-polyfill');
window.bodyScrollLock = require('body-scroll-lock'); // Block scrolling when modal is showed

function handleDOMContentLoaded() {
  const viewName = document.getElementsByTagName('body')[0].dataset.jsViewName;
  const ViewClass = loadView(viewName);
  const view = new ViewClass();
  view.mount();
  window.currentView = view;
}

function handleDocumentUnload() {
  window.currentView.unmount();
}

window.addEventListener('DOMContentLoaded', handleDOMContentLoaded, false);
window.addEventListener('unload', handleDocumentUnload, false);
