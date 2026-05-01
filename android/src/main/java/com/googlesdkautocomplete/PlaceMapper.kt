package com.googlesdkautocomplete

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.WritableArray
import com.facebook.react.bridge.WritableMap
import com.google.android.gms.maps.model.LatLng
import com.google.android.gms.maps.model.LatLngBounds
import com.google.android.libraries.places.api.model.AddressComponent
import com.google.android.libraries.places.api.model.OpeningHours
import com.google.android.libraries.places.api.model.Period
import com.google.android.libraries.places.api.model.Place
import com.google.android.libraries.places.api.model.Place.BooleanPlaceAttributeValue
import com.google.android.libraries.places.api.model.PlusCode
import com.google.android.libraries.places.api.model.Review
import com.google.android.libraries.places.api.model.TimeOfWeek

internal object PlaceMapper {

  fun toMap(place: Place, requested: Set<String>): WritableMap {
    val m = Arguments.createMap()
    fun has(field: String) = field in requested

    if (has("id")) place.id?.let { m.putString("id", it) }
    if (has("displayName")) place.displayName?.let { m.putString("displayName", it) }
    if (has("formattedAddress")) place.formattedAddress?.let { m.putString("formattedAddress", it) }
    if (has("shortFormattedAddress")) place.shortFormattedAddress?.let { m.putString("shortFormattedAddress", it) }
    if (has("addressComponents")) place.addressComponents?.asList()?.let {
      m.putArray("addressComponents", addressComponentsArray(it))
    }
    if (has("location")) place.location?.let { m.putMap("location", latLngMap(it)) }
    if (has("viewport")) place.viewport?.let { m.putMap("viewport", viewportMap(it)) }
    if (has("plusCode")) place.plusCode?.let { m.putMap("plusCode", plusCodeMap(it)) }
    if (has("types")) place.placeTypes?.let {
      val arr = Arguments.createArray()
      for (t in it) arr.pushString(t)
      m.putArray("types", arr)
    }
    if (has("primaryType")) place.primaryType?.let { m.putString("primaryType", it) }
    if (has("primaryTypeDisplayName")) place.primaryTypeDisplayName?.let { m.putString("primaryTypeDisplayName", it) }
    if (has("businessStatus")) place.businessStatus?.let { m.putString("businessStatus", it.name) }
    if (has("rating")) place.rating?.let { m.putDouble("rating", it) }
    if (has("userRatingCount")) place.userRatingCount?.let { m.putInt("userRatingCount", it) }
    if (has("priceLevel")) place.priceLevel?.let { m.putString("priceLevel", priceLevelName(it)) }
    if (has("websiteUri")) place.websiteUri?.toString()?.let { m.putString("websiteUri", it) }
    if (has("googleMapsUri")) place.googleMapsUri?.toString()?.let { m.putString("googleMapsUri", it) }
    if (has("iconMaskUrl")) place.iconMaskUrl?.let { m.putString("iconMaskUrl", it) }
    if (has("iconBackgroundColor")) place.iconBackgroundColor?.let { m.putInt("iconBackgroundColor", it) }
    if (has("internationalPhoneNumber")) place.internationalPhoneNumber?.let { m.putString("internationalPhoneNumber", it) }
    if (has("nationalPhoneNumber")) place.nationalPhoneNumber?.let { m.putString("nationalPhoneNumber", it) }
    if (has("utcOffsetMinutes")) place.utcOffsetMinutes?.let { m.putInt("utcOffsetMinutes", it) }
    if (has("openingHours")) place.openingHours?.let { m.putMap("openingHours", openingHoursMap(it)) }
    if (has("currentOpeningHours")) place.currentOpeningHours?.let {
      m.putMap("currentOpeningHours", openingHoursMap(it))
    }
    if (has("secondaryOpeningHours")) place.secondaryOpeningHours?.let {
      m.putArray("secondaryOpeningHours", openingHoursArray(it))
    }
    if (has("currentSecondaryOpeningHours")) place.currentSecondaryOpeningHours?.let {
      m.putArray("currentSecondaryOpeningHours", openingHoursArray(it))
    }
    if (has("editorialSummary")) place.editorialSummary?.let { m.putString("editorialSummary", it) }
    if (has("reviews")) place.reviews?.let { m.putArray("reviews", reviewsArray(it)) }
    if (has("accessibilityOptions")) place.accessibilityOptions?.let { ao ->
      val outer = Arguments.createMap()
      putTribool(outer, "wheelchairAccessibleParking", ao.wheelchairAccessibleParking)
      putTribool(outer, "wheelchairAccessibleEntrance", ao.wheelchairAccessibleEntrance)
      putTribool(outer, "wheelchairAccessibleRestroom", ao.wheelchairAccessibleRestroom)
      putTribool(outer, "wheelchairAccessibleSeating", ao.wheelchairAccessibleSeating)
      m.putMap("accessibilityOptions", outer)
    }

    putBool(m, requested, "allowsDogs", place.allowsDogs)
    putBool(m, requested, "curbsidePickup", place.curbsidePickup)
    putBool(m, requested, "delivery", place.delivery)
    putBool(m, requested, "dineIn", place.dineIn)
    putBool(m, requested, "takeout", place.takeout)
    putBool(m, requested, "goodForChildren", place.goodForChildren)
    putBool(m, requested, "goodForGroups", place.goodForGroups)
    putBool(m, requested, "goodForWatchingSports", place.goodForWatchingSports)
    putBool(m, requested, "liveMusic", place.liveMusic)
    putBool(m, requested, "menuForChildren", place.menuForChildren)
    putBool(m, requested, "outdoorSeating", place.outdoorSeating)
    putBool(m, requested, "reservable", place.reservable)
    putBool(m, requested, "restroom", place.restroom)
    putBool(m, requested, "servesBeer", place.servesBeer)
    putBool(m, requested, "servesWine", place.servesWine)
    putBool(m, requested, "servesCoffee", place.servesCoffee)
    putBool(m, requested, "servesBreakfast", place.servesBreakfast)
    putBool(m, requested, "servesLunch", place.servesLunch)
    putBool(m, requested, "servesDinner", place.servesDinner)
    putBool(m, requested, "servesBrunch", place.servesBrunch)
    putBool(m, requested, "servesDessert", place.servesDessert)
    putBool(m, requested, "servesVegetarianFood", place.servesVegetarianFood)

    if (has("parkingOptions")) place.parkingOptions?.let { po ->
      val out = Arguments.createMap()
      putTribool(out, "freeParkingLot", po.freeParkingLot)
      putTribool(out, "paidParkingLot", po.paidParkingLot)
      putTribool(out, "freeStreetParking", po.freeStreetParking)
      putTribool(out, "paidStreetParking", po.paidStreetParking)
      putTribool(out, "valetParking", po.valetParking)
      putTribool(out, "freeGarageParking", po.freeGarageParking)
      putTribool(out, "paidGarageParking", po.paidGarageParking)
      m.putMap("parkingOptions", out)
    }
    if (has("paymentOptions")) place.paymentOptions?.let { pmo ->
      val out = Arguments.createMap()
      putTribool(out, "acceptsCreditCards", pmo.acceptsCreditCards)
      putTribool(out, "acceptsDebitCards", pmo.acceptsDebitCards)
      putTribool(out, "acceptsCashOnly", pmo.acceptsCashOnly)
      putTribool(out, "acceptsNfc", pmo.acceptsNfc)
      m.putMap("paymentOptions", out)
    }
    if (has("fuelOptions")) place.fuelOptions?.let { fo ->
      val fm = Arguments.createMap()
      val prices = Arguments.createArray()
      fo.fuelPrices?.forEach { price ->
        val pm = Arguments.createMap()
        price.type?.let { pm.putString("type", it.toString()) }
        price.price?.let { money ->
          money.currencyCode?.let { pm.putString("currencyCode", it) }
          money.units?.let { pm.putString("priceUnits", it.toString()) }
          money.nanos?.let { pm.putInt("priceNanos", it) }
        }
        price.updateTime?.let { pm.putDouble("updateTime", it.toEpochMilli().toDouble()) }
        prices.pushMap(pm)
      }
      fm.putArray("fuelPrices", prices)
      m.putMap("fuelOptions", fm)
    }
    if (has("evChargeOptions")) place.evChargeOptions?.let { ev ->
      val em = Arguments.createMap()
      ev.connectorCount?.let { em.putInt("connectorCount", it) }
      val aggs = Arguments.createArray()
      ev.connectorAggregations?.forEach { agg ->
        val am = Arguments.createMap()
        agg.type?.let { am.putString("type", it.toString()) }
        agg.maxChargeRateKw?.let { am.putDouble("maxChargeRateKw", it) }
        agg.count?.let { am.putInt("count", it) }
        agg.availableCount?.let { am.putInt("availableCount", it) }
        agg.outOfServiceCount?.let { am.putInt("outOfServiceCount", it) }
        aggs.pushMap(am)
      }
      em.putArray("connectorAggregations", aggs)
      m.putMap("evChargeOptions", em)
    }

    return m
  }

  // BooleanPlaceAttributeValue is a tribool: TRUE / FALSE / UNKNOWN.
  // We expose only TRUE/FALSE to JS — UNKNOWN means the field is absent.
  private fun triboolToBool(v: BooleanPlaceAttributeValue?): Boolean? = when (v) {
    BooleanPlaceAttributeValue.TRUE -> true
    BooleanPlaceAttributeValue.FALSE -> false
    else -> null
  }

  private fun putBool(
    m: WritableMap,
    requested: Set<String>,
    key: String,
    value: BooleanPlaceAttributeValue?
  ) {
    if (key !in requested) return
    val b = triboolToBool(value) ?: return
    m.putBoolean(key, b)
  }

  private fun putTribool(m: WritableMap, key: String, value: BooleanPlaceAttributeValue?) {
    val b = triboolToBool(value) ?: return
    m.putBoolean(key, b)
  }

  private fun latLngMap(p: LatLng): WritableMap {
    val m = Arguments.createMap()
    m.putDouble("latitude", p.latitude)
    m.putDouble("longitude", p.longitude)
    return m
  }

  private fun viewportMap(b: LatLngBounds): WritableMap {
    val m = Arguments.createMap()
    m.putMap("northEast", latLngMap(b.northeast))
    m.putMap("southWest", latLngMap(b.southwest))
    return m
  }

  private fun plusCodeMap(c: PlusCode): WritableMap {
    val m = Arguments.createMap()
    c.compoundCode?.let { m.putString("compoundCode", it) }
    c.globalCode?.let { m.putString("globalCode", it) }
    return m
  }

  private fun addressComponentsArray(comps: List<AddressComponent>): WritableArray {
    val arr = Arguments.createArray()
    for (c in comps) {
      val m = Arguments.createMap()
      c.shortName?.let { m.putString("shortName", it) }
      c.name?.let { m.putString("longName", it) }
      val types = Arguments.createArray()
      c.types?.forEach { types.pushString(it) }
      m.putArray("types", types)
      arr.pushMap(m)
    }
    return arr
  }

  private fun openingHoursArray(list: List<OpeningHours>): WritableArray {
    val arr = Arguments.createArray()
    for (h in list) arr.pushMap(openingHoursMap(h))
    return arr
  }

  private fun openingHoursMap(h: OpeningHours): WritableMap {
    val m = Arguments.createMap()
    val periods = Arguments.createArray()
    h.periods?.forEach { p -> periods.pushMap(periodMap(p)) }
    m.putArray("periods", periods)
    val weekdays = Arguments.createArray()
    h.weekdayText?.forEach { weekdays.pushString(it) }
    m.putArray("weekdayText", weekdays)
    return m
  }

  private fun periodMap(p: Period): WritableMap {
    val m = Arguments.createMap()
    p.open?.let { m.putMap("open", timeOfWeekMap(it)) }
    p.close?.let { m.putMap("close", timeOfWeekMap(it)) }
    return m
  }

  private fun timeOfWeekMap(t: TimeOfWeek): WritableMap {
    val m = Arguments.createMap()
    m.putInt("day", t.day.ordinal)
    m.putInt("hour", t.time.hours)
    m.putInt("minute", t.time.minutes)
    return m
  }

  private fun reviewsArray(reviews: List<Review>): WritableArray {
    val arr = Arguments.createArray()
    for (r in reviews) {
      val m = Arguments.createMap()
      r.text?.let { m.putString("text", it) }
      r.originalText?.let { m.putString("originalText", it) }
      r.rating?.let { m.putDouble("rating", it) }
      r.publishTime?.let { m.putString("publishTime", it) }
      r.relativePublishTimeDescription?.let { m.putString("relativePublishTimeDescription", it) }
      r.authorAttribution?.let { aa ->
        val am = Arguments.createMap()
        aa.name?.let { am.putString("displayName", it) }
        aa.uri?.let { am.putString("uri", it) }
        aa.photoUri?.let { am.putString("photoUri", it) }
        m.putMap("authorAttribution", am)
      }
      arr.pushMap(m)
    }
    return arr
  }

  private fun priceLevelName(level: Int): String = when (level) {
    0 -> "FREE"
    1 -> "INEXPENSIVE"
    2 -> "MODERATE"
    3 -> "EXPENSIVE"
    4 -> "VERY_EXPENSIVE"
    else -> "MODERATE"
  }
}
