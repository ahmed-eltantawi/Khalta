class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://www.themealdb.com/api/json/v1/1';

  // Endpoints
  static const String searchByName = '/search.php';    // ?s=name
  static const String searchByLetter = '/search.php';  // ?f=a
  static const String lookupById = '/lookup.php';       // ?i=id
  static const String random = '/random.php';
  static const String categories = '/categories.php';
  static const String list = '/list.php';               // ?c=list | ?a=list | ?i=list
  static const String filter = '/filter.php';           // ?i=ingredient | ?c=category | ?a=area

  // Ingredient image base
  static const String ingredientImageBase =
      'https://www.themealdb.com/images/ingredients/';

  static String ingredientImageUrl(String ingredient) =>
      '$ingredientImageBase${ingredient.replaceAll(' ', '%20')}-Small.png';
}
