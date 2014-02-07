openprojectApp.directive('sortHeader', ['I18n', 'PathHelper', function(I18n, PathHelper){

  var defaultSortDirection = 'asc';

  var Sortation = function(encodedSortation) {
    if (encodedSortation) {
      this.sortElements = encodedSortation.split(',').map(function(sortParam) {
        fieldAndDirection = sortParam.split(':');
        return { field: fieldAndDirection[0], direction: fieldAndDirection[1] || defaultSortDirection};
      });
    } else {
      this.sortElements = [];
    }
  };

  Sortation.prototype.getPrimarySortationCriterion = function() {
    return this.sortElements.first();
  };

  Sortation.prototype.getDisplayedSortDirectionOfHeader = function(headerName) {
    var sortDirection, displayedSortation = this.getPrimarySortationCriterion();

    if(displayedSortation && displayedSortation.field === headerName) sortDirection = displayedSortation.direction;

    return sortDirection;
  };

  Sortation.prototype.getCurrentSortDirectionOfHeader = function(headerName) {
    var sortDirection;

    angular.forEach(this.sortElements, function(sortation){
      if(sortation && sortation.field === headerName) sortDirection = sortation.direction;
    });

    return sortDirection;
  };

  Sortation.prototype.removeSortElement = function(elementName) {
    index = this.sortElements.map(function(sortation){
      return sortation.field;
    }).indexOf(elementName);

    if (index !== -1) this.sortElements.splice(index, 1);
  };

  Sortation.prototype.addSortElement = function(sortElement) {
    this.removeSortElement(sortElement.field);

    this.sortElements.unshift(sortElement);
  };

  Sortation.prototype.getTargetSortationOfHeader = function(headerName) {
    var targetSortation = angular.copy(this);
    var targetSortDirection = this.getCurrentSortDirectionOfHeader(headerName) === 'asc' ? 'desc' : 'asc';

    targetSortation.addSortElement({field: headerName, direction: targetSortDirection}, targetSortation);

    return targetSortation;
  };

  Sortation.prototype.encode = function() {
    return this.sortElements.map(function(sortation){
      if (sortation.direction === 'asc') {
        return sortation.field;
      } else {
        return [sortation.field, sortation.direction].join(':');
      }
    }).join(',');
  };

  return {
    restrict: 'A',
    templateUrl: '/templates/work_packages/sort_header.html',
    scope: true,
    link: function(scope, element, attributes) {
      headerName = attributes['headerName'];

      sortation = new Sortation(scope.currentSortation);
      scope.sortation = sortation;
      targetSortation = sortation.getTargetSortationOfHeader(headerName);

      scope.headerTitle = attributes['headerTitle'];
      scope.sortable = attributes['sortable'];
      scope.path = PathHelper.projectWorkPackagesPath(scope.projectIdentifier);

      scope.currentSortDirection = sortation.getDisplayedSortDirectionOfHeader(headerName);

      scope.queryString = 'set_filter=1&sort=' + targetSortation.encode();

    }
  };
}]);
