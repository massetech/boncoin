import "phoenix_html";
// import socket from "./socket"
// import "../css/variables.scss"  // Import first to modify Bootrap
// import "~bootstrap/dist/css/bootstrap"  // Import first to modify Bootrap
// import "../css/design.scss"  // Import first to modify Bootrap
import "../css/app.scss";    // imports scss files in the right order

import 'bootstrap';                   // imports Boostrap js functions
import 'jquery-touchswipe';           // imports touchswipe effects
import 'ekko-lightbox';
import "../vendor/bootstrap-select-1.13.0-beta/js/bootstrap-select";
import "../vendor/custom_scroller/jquery.mCustomScrollbar.concat.min";
import "../vendor/slim/js/slim.kickstart.min";
// import "../vendor/meaning_of_life";

import loadView from './views/loader';          // Custom js to run code per page
window.__socket = require("phoenix").Socket;    // Fix for webpack with drab

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
