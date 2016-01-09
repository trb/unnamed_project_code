angular.module('Login', [])

.controller('loginController', [
    '$location',
    '$scope',
    ($location, $scope) ->
      $scope.email = '';
      $scope.password = '';
      $scope.showError = false

      $scope.login = ->
        if $scope.email == '' || $scope.password == ''
          $scope.showError = true
        else
          $scope.showError = false
          $location.url('/shops')
  ])
