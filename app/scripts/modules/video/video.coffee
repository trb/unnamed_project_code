video = angular.module 'Video', ['ngCookies']

video.directive('videoPlayer', [
  '$location',
  ($location) ->
    restrict: 'E',
    templateUrl: 'views/modules/video/videoPlayer.html',
    link: ($scope, $element) ->
      $scope.onAir = false
      $scope.call = () ->
        $scope.onAir = true

      gapi.hangout.render('hangout', {
        render: 'createhangout',
        widget_size: 72,
        invites: [
          {
            id: '113131597485387162824',
            invite_type: 'PROFILE'
          },
          {
            id: '116239544120999981614',
            invite_type: 'PROFILE'
          }
        ]
      });
])
