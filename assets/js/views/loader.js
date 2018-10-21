import MainView from './main'
import UserNew_user_announceView from './public/offer_form'
import AnnouncePublic_indexView from './public/offer_index'

// Find them on the body tag of view mounted
const views = {
  UserNew_user_announceView,
  AnnouncePublic_indexView
};

export default function loadView(viewName) {
  return views[viewName] || MainView
}
