package com.googlesdkautocomplete

import android.graphics.Typeface
import android.text.Spanned
import android.text.style.CharacterStyle
import android.text.style.StyleSpan
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.WritableArray
import com.facebook.react.bridge.WritableMap
import com.google.android.libraries.places.api.model.AutocompletePrediction

internal object PredictionMapper {

  fun toArray(predictions: List<AutocompletePrediction>): WritableArray {
    val arr = Arguments.createArray()
    for (p in predictions) arr.pushMap(toMap(p))
    return arr
  }

  private fun toMap(p: AutocompletePrediction): WritableMap {
    val m = Arguments.createMap()
    m.putString("placeId", p.placeId)
    m.putMap("fullText", attributedText { p.getFullText(it) })
    m.putMap("primaryText", attributedText { p.getPrimaryText(it) })
    m.putMap("secondaryText", attributedText { p.getSecondaryText(it) })

    val types = Arguments.createArray()
    for (t in p.types) types.pushString(t)
    m.putArray("types", types)

    val distance = p.distanceMeters
    if (distance != null) m.putInt("distanceMeters", distance)

    return m
  }

  // Calls the prediction's get*Text(CharacterStyle) with a fresh StyleSpan,
  // then walks the resulting Spanned to extract every styled range.
  // The Places SDK applies the supplied CharacterStyle to each matched
  // substring; iterating the spans gives us the (offset, length) tuples.
  private fun attributedText(getter: (CharacterStyle) -> CharSequence): WritableMap {
    val styled = getter(StyleSpan(Typeface.BOLD)) as Spanned
    val text = styled.toString()
    val matches = Arguments.createArray()
    val seen = mutableSetOf<Pair<Int, Int>>()
    val spans = styled.getSpans(0, styled.length, CharacterStyle::class.java)
    for (span in spans) {
      val start = styled.getSpanStart(span)
      val end = styled.getSpanEnd(span)
      if (start < 0 || end <= start) continue
      val key = start to end
      if (!seen.add(key)) continue
      val match = Arguments.createMap()
      match.putInt("offset", start)
      match.putInt("length", end - start)
      matches.pushMap(match)
    }
    val out = Arguments.createMap()
    out.putString("text", text)
    out.putArray("matches", matches)
    return out
  }
}
