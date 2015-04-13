angular.module('Navigation', [])

  .directive('markAsCurrent', [
    '$location',
    ($location) ->
      restrict: 'A',
      link: ($scope, $element, $attributes) ->
        $scope.$watch(
          -> $location.path(),
          ->
            if $attributes.markAsCurrent == $location.path()
              $element.addClass('active')
            else
              $element.removeClass('active')
        )
  ])

  .directive('navigation', [
    'Authentication',
    (authentication) ->
      restrict: 'E'
      link: ($scope) ->
        $scope.user = authentication.getCurrentUser()

      templateUrl: '/views/modules/navigation/navigation.html'
  ])

  .directive('navigationItem', [
    ->
      restrict: 'E'
      scope:
        url: '@'
      replace: true
      transclude: true
      templateUrl: '/views/modules/navigation/menuItem.html'
  ])
