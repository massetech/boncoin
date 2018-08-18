import "phoenix_html";
// import socket from "./socket"

// Import CSS
import "../css/app.scss";
// Import static images
function requireAll(r) { r.keys().forEach(r); }
requireAll(require.context('../static/images/', true, /\.(png|gif|svg|jpg|jpeg)$/));
// requireAll(require.context('../static/images/flags', true, /\.(png|gif|svg|jpg|jpeg)$/));

import '../node_modules/bootstrap';                   // imports Boostrap js functions
import '../node_modules/jquery-touchswipe';           // imports touchswipe effects
import '../node_modules/ekko-lightbox';
import "../vendor/bootstrap-select-1.13.0-beta/js/bootstrap-select";
// import "../vendor/custom_scroller/jquery.mCustomScrollbar.concat.min";
import "../vendor/slim/js/slim.kickstart.min";

import loadView from './views/loader';          // Custom js to run code per page
window.__socket = require("phoenix").Socket;    // Fix for webpack with drab

function handleDOMContentLoaded() {
  const viewName = document.getElementsByTagName('body')[0].dataset.jsViewName;
  // console.log(viewName)
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
