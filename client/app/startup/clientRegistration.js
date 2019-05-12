import ReactOnRails from 'react-on-rails';
import Promise from 'es6-promise';
Promise.polyfill();

import OnboardingTopBar from './OnboardingTopBarApp';
import OnboardingGuideApp from './OnboardingGuideApp';

ReactOnRails.register({
  OnboardingGuideApp,
  OnboardingTopBar,
});

ReactOnRails.registerStore({
});
