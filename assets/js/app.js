import "phoenix_html"
// import socket from "./socket"
import Css from '../css/app.scss'

import "../node_modules/bootstrap/dist/js/bootstrap.min" // imports Boostrap js functions
import '../node_modules/jquery-touchswipe/jquery.touchSwipe.min'          // imports touchswipe effects
import "../vendor/slim/js/slim.kickstart.min"
import "../vendor/bootstrap-select-1.13.0-beta/js/bootstrap-select.min"

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
