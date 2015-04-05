angular.module('Login', [])

.controller('loginController', [
    '$location',
    '$scope',
    ($location, $scope) ->
      $scope.email = '';
      $scope.password = '';

      $scope.login = ->
        if $scope.email != '' && $scope.password != ''
          $location.url('/video')
  ])
