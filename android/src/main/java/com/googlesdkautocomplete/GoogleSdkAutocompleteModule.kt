package com.googlesdkautocomplete

import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.bridge.ReadableMap
import com.google.android.gms.common.api.ApiException
import com.google.android.gms.maps.model.LatLng
import com.google.android.libraries.places.api.Places
import com.google.android.libraries.places.api.model.CircularBounds
import com.google.android.libraries.places.api.model.LocationBias
import com.google.android.libraries.places.api.model.LocationRestriction
import com.google.android.libraries.places.api.model.RectangularBounds
import com.google.android.libraries.places.api.net.FetchPlaceRequest
import com.google.android.libraries.places.api.net.FindAutocompletePredictionsRequest
import com.google.android.libraries.places.api.net.PlacesClient

class GoogleSdkAutocompleteModule(reactContext: ReactApplicationContext) :
  NativeGoogleSdkAutocompleteSpec(reactContext) {

  private val tokens = SessionTokenStore()

  @Volatile
  private var client: PlacesClient? = null

  @Volatile
  private var initializedKey: String? = null

  override fun getName(): String = NAME

  override fun initialize(apiKey: String, promise: Promise) {
    try {
      val ctx = reactApplicationContext.applicationContext
      synchronized(this) {
        if (initializedKey == null) {
          Places.initializeWithNewPlacesApiEnabled(ctx, apiKey)
          client = Places.createClient(ctx)
          initializedKey = apiKey
        } else if (initializedKey != apiKey) {
          throw IllegalStateException(
            "Places already initialized with a different API key"
          )
        }
      }
      promise.resolve(null)
    } catch (e: Throwable) {
      promise.reject(errorCodeFor(e), e.localizedMessage, e)
    }
  }

  override fun createSessionToken(promise: Promise) {
    try {
      requireInitialized()
      promise.resolve(tokens.create())
    } catch (e: Throwable) {
      promise.reject(errorCodeFor(e), e.localizedMessage, e)
    }
  }

  override fun clearSessionToken(token: String, promise: Promise) {
    try {
      tokens.clear(token)
      promise.resolve(null)
    } catch (e: Throwable) {
      promise.reject(errorCodeFor(e), e.localizedMessage, e)
    }
  }

  override fun findAutocompletePredictions(request: ReadableMap, promise: Promise) {
    try {
      val placesClient = requireInitialized()

      val builder = FindAutocompletePredictionsRequest.builder()
        .setQuery(request.getString("query") ?: throw IllegalArgumentException("query required"))

      request.getString("sessionToken")?.let { id ->
        val tok = tokens.get(id) ?: throw SessionTokenNotFound(id)
        builder.setSessionToken(tok)
      }
      request.getArray("types")?.let { builder.setTypesFilter(stringList(it)) }
      request.getArray("countries")?.let { builder.setCountries(stringList(it)) }
      request.getMap("locationBias")?.let { builder.setLocationBias(toBounds(it) as LocationBias) }
      request.getMap("locationRestriction")?.let { builder.setLocationRestriction(toBounds(it) as LocationRestriction) }
      request.getMap("origin")?.let { builder.setOrigin(toLatLng(it)) }
      if (request.hasKey("regionCode")) request.getString("regionCode")?.let { builder.setRegionCode(it) }
      if (request.hasKey("inputOffset") && !request.isNull("inputOffset")) {
        builder.setInputOffset(request.getInt("inputOffset"))
      }

      placesClient.findAutocompletePredictions(builder.build())
        .addOnSuccessListener { response ->
          promise.resolve(PredictionMapper.toArray(response.autocompletePredictions))
        }
        .addOnFailureListener { e ->
          promise.reject(errorCodeFor(e), e.localizedMessage, e)
        }
    } catch (e: Throwable) {
      promise.reject(errorCodeFor(e), e.localizedMessage, e)
    }
  }

  override fun fetchPlace(request: ReadableMap, promise: Promise) {
    try {
      val placesClient = requireInitialized()

      val placeId = request.getString("placeId")
        ?: throw IllegalArgumentException("placeId required")
      val fieldsArr = request.getArray("fields")
        ?: throw IllegalArgumentException("fields required")
      val jsFields = stringList(fieldsArr)
      val sdkFields = FieldMapper.toSdkFields(jsFields)
      val requested = jsFields.toSet()

      val sessionTokenId = request.getString("sessionToken")

      val reqBuilder = FetchPlaceRequest.builder(placeId, sdkFields)
      sessionTokenId?.let { id ->
        val tok = tokens.get(id) ?: throw SessionTokenNotFound(id)
        reqBuilder.setSessionToken(tok)
      }
      val req = reqBuilder.build()

      placesClient.fetchPlace(req)
        .addOnSuccessListener { response ->
          // Auto-clear the session token after a successful fetchPlace,
          // matching Google's billing-session model.
          sessionTokenId?.let { tokens.clear(it) }
          promise.resolve(PlaceMapper.toMap(response.place, requested))
        }
        .addOnFailureListener { e ->
          promise.reject(errorCodeFor(e), e.localizedMessage, e)
        }
    } catch (e: Throwable) {
      promise.reject(errorCodeFor(e), e.localizedMessage, e)
    }
  }

  // ---- helpers ----

  private fun requireInitialized(): PlacesClient {
    return client ?: throw NotInitializedException()
  }

  // Returns a CircularBounds or RectangularBounds. Both implement
  // LocationBias and LocationRestriction, so callers can cast to either.
  private fun toBounds(m: ReadableMap): Any {
    return when (m.getString("type")) {
      "circle" -> {
        val center = m.getMap("center") ?: throw IllegalArgumentException("circle.center required")
        val radius = m.getDouble("radiusMeters")
        CircularBounds.newInstance(toLatLng(center), radius)
      }
      "rectangle" -> {
        val ne = m.getMap("northEast") ?: throw IllegalArgumentException("rectangle.northEast required")
        val sw = m.getMap("southWest") ?: throw IllegalArgumentException("rectangle.southWest required")
        RectangularBounds.newInstance(toLatLng(sw), toLatLng(ne))
      }
      else -> throw IllegalArgumentException("Unknown location type: ${m.getString("type")}")
    }
  }

  private fun toLatLng(m: ReadableMap): LatLng {
    return LatLng(m.getDouble("latitude"), m.getDouble("longitude"))
  }

  private fun stringList(arr: ReadableArray): List<String> {
    val out = ArrayList<String>(arr.size())
    for (i in 0 until arr.size()) out.add(arr.getString(i) ?: "")
    return out
  }

  private fun errorCodeFor(e: Throwable): String {
    return when (e) {
      is NotInitializedException -> "NOT_INITIALIZED"
      is SessionTokenNotFound -> "UNKNOWN_SESSION_TOKEN"
      is IllegalArgumentException -> "INVALID_REQUEST"
      is ApiException -> {
        val code = e.statusCode
        if (code == 7 || code == 8 || code == 14) "NETWORK_ERROR" else "API_ERROR"
      }
      else -> "UNKNOWN"
    }
  }

  private class NotInitializedException :
    IllegalStateException("Places.initialize(apiKey) must be called first")

  private class SessionTokenNotFound(id: String) :
    IllegalArgumentException("Unknown session token: $id")

  companion object {
    const val NAME = NativeGoogleSdkAutocompleteSpec.NAME
  }
}
