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
            id: 'aclarkd@gmail.com',
            invite_type: 'EMAIL'
          },
          {
            id: 'thomas.rubbert@gmail.com',
            invite_type: 'EMAIL'
          }
        ]
      });
])
