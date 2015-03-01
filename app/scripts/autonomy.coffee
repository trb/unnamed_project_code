
class AutonomyController
    constructor: ($scope) ->
        $scope.foundation = 'ooo la la'

AutonomyController.done

app = angular.module('autonomyApp', [])

.controller("autonomyController",
    AutonomyController)


