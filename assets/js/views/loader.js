import MainView    from './main';
// import PublicDashboardView from './public/dashboard';


const views = {
  // PublicDashboardView
};

export default function loadView(viewName) {
  return views[viewName] || MainView;
}
