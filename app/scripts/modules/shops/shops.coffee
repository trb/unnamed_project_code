angular.module('Shops', ['Video'])

  .service('Shops', [
    ->
      data: [
        {
          id: 1
          name: 'False Creek Collision',
          location: {
            address: '6660 Royal Oak Ave',
            city: 'Burnaby',
            province: 'BC'
          },
          contacts: [
            {
              name: 'Kyle Kidner',
              role: 'Estimator',
              status: 'available',
              id: '3kl253'
            },
            {
              name: 'Bernhard Rubbert',
              role: 'Owner',
              status: 'offline',
              id: '2jb65k2'
            }
          ]
        },
        {
          id: 2
          name: 'Trevor Collision',
          location: {
            address: '7732 Sunshine Way',
            city: 'Coquitlam',
            province: 'BC'
          },
          contacts: [
            {
              name: 'Trevor Miles',
              role: 'Owner',
              status: 'available',
              id: '81b51l'
            }
          ]
        },
        {
          id: 3
          name: 'Craftsman Collision Kitsilano',
          location: {
            address: '1514 West 12th Ave',
            city: 'Vancouver',
            province: 'BC'
          },
          contacts: [
            {
              name: 'Mark Burnham',
              role: 'General Manager',
              status: 'available',
              id: '132bgs87'
            },
            {
              name: 'Miles Dunn',
              role: 'Estimator',
              status: 'available',
              id: '4561ged1'
            },
          ]
        },
        {
          id: 4
          name: 'Craftsman Collision Richmond',
          location: {
            address: '2158 Number 5 Rd',
            city: 'Richmond',
            province: 'BC'
          },
          contacts: [
            {
              name: 'Patrick Lee',
              role: 'Estimator',
              status: 'available',
              id: '132bgs87'
            }
          ]
        }
      ]
  ])

  .directive('shopsList', [
    '$location',
    'Shops'
    ($location, shops) ->
      controller: ->
        this.openList = {}
        this.autoOpenList = {}

        this.shops =
          list: shops.data

        this.search = =>
          if (_.isEmpty(this.searchQuery))
            this.shops.list = shops.data
          else
            this.shops.list = _.filter(shops.data, (shop) =>
              if shop.name.toLowerCase().indexOf(this.searchQuery.toLowerCase()) >= 0
                return true

              return _.chain(shop.contacts)
                .filter((contact) =>
                  return contact.name.toLowerCase().indexOf(this.searchQuery.toLowerCase()) >= 0
                )
                .any()
                .value()
            )

          if this.shops.list.length == 1
            this.autoOpenList[this.shops.list[0].id] = true
          else
            this.autoOpenList = {}

        this.toggle = (id) =>
          if this.openList[id]
            delete this.openList[id]
          else
            this.openList[id] = true

        this.startCall = (id) =>
          $location.url('/video?call=' + id)

        return

      controllerAs: 'shops'
      restrict: 'E'
      scope: {}
      templateUrl: 'views/modules/shops/shopsList.html'
  ])
