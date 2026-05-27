package com.googlesdkautocomplete

import com.google.android.libraries.places.api.model.Place

internal object FieldMapper {
  private val js2sdk: Map<String, Place.Field> = mapOf(
    "id" to Place.Field.ID,
    "addressComponents" to Place.Field.ADDRESS_COMPONENTS,
    "formattedAddress" to Place.Field.FORMATTED_ADDRESS,
    "location" to Place.Field.LOCATION,
    "plusCode" to Place.Field.PLUS_CODE,
    "types" to Place.Field.TYPES,
    "viewport" to Place.Field.VIEWPORT,
    "businessStatus" to Place.Field.BUSINESS_STATUS,
    "displayName" to Place.Field.DISPLAY_NAME,
    "googleMapsUri" to Place.Field.GOOGLE_MAPS_URI,
    "iconBackgroundColor" to Place.Field.ICON_BACKGROUND_COLOR,
    "iconMaskUrl" to Place.Field.ICON_MASK_URL,
    "utcOffsetMinutes" to Place.Field.UTC_OFFSET,
    "currentOpeningHours" to Place.Field.CURRENT_OPENING_HOURS,
    // iOS exposes only one phone number (international format), so we expose
    // just the international number for cross-platform parity.
    "internationalPhoneNumber" to Place.Field.INTERNATIONAL_PHONE_NUMBER,
    "openingHours" to Place.Field.OPENING_HOURS,
    "secondaryOpeningHours" to Place.Field.SECONDARY_OPENING_HOURS,
    "priceLevel" to Place.Field.PRICE_LEVEL,
    "rating" to Place.Field.RATING,
    "userRatingCount" to Place.Field.USER_RATING_COUNT,
    "websiteUri" to Place.Field.WEBSITE_URI,
    "allowsDogs" to Place.Field.ALLOWS_DOGS,
    "curbsidePickup" to Place.Field.CURBSIDE_PICKUP,
    "delivery" to Place.Field.DELIVERY,
    "dineIn" to Place.Field.DINE_IN,
    "takeout" to Place.Field.TAKEOUT,
    "editorialSummary" to Place.Field.EDITORIAL_SUMMARY,
    "evChargeOptions" to Place.Field.EV_CHARGE_OPTIONS,
    "fuelOptions" to Place.Field.FUEL_OPTIONS,
    "goodForChildren" to Place.Field.GOOD_FOR_CHILDREN,
    "goodForGroups" to Place.Field.GOOD_FOR_GROUPS,
    "goodForWatchingSports" to Place.Field.GOOD_FOR_WATCHING_SPORTS,
    "liveMusic" to Place.Field.LIVE_MUSIC,
    "menuForChildren" to Place.Field.MENU_FOR_CHILDREN,
    "outdoorSeating" to Place.Field.OUTDOOR_SEATING,
    "parkingOptions" to Place.Field.PARKING_OPTIONS,
    "paymentOptions" to Place.Field.PAYMENT_OPTIONS,
    "reservable" to Place.Field.RESERVABLE,
    "restroom" to Place.Field.RESTROOM,
    "reviews" to Place.Field.REVIEWS,
    "accessibilityOptions" to Place.Field.ACCESSIBILITY_OPTIONS,
    "servesBeer" to Place.Field.SERVES_BEER,
    "servesWine" to Place.Field.SERVES_WINE,
    "servesCoffee" to Place.Field.SERVES_COFFEE,
    "servesBreakfast" to Place.Field.SERVES_BREAKFAST,
    "servesLunch" to Place.Field.SERVES_LUNCH,
    "servesDinner" to Place.Field.SERVES_DINNER,
    "servesBrunch" to Place.Field.SERVES_BRUNCH,
    "servesDessert" to Place.Field.SERVES_DESSERT,
    "servesVegetarianFood" to Place.Field.SERVES_VEGETARIAN_FOOD
  )

  fun toSdkFields(jsFields: List<String>): List<Place.Field> {
    val unknown = jsFields.filter { it !in js2sdk }
    if (unknown.isNotEmpty()) {
      throw IllegalArgumentException("Unknown PlaceField(s): ${unknown.joinToString()}")
    }
    return jsFields.map { js2sdk.getValue(it) }
  }

  fun isRequested(jsField: String, requested: Set<String>): Boolean = jsField in requested
}
