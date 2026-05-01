package com.googlesdkautocomplete

import com.google.android.libraries.places.api.model.AutocompleteSessionToken
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap

internal class SessionTokenStore {
  private val tokens = ConcurrentHashMap<String, AutocompleteSessionToken>()

  fun create(): String {
    val id = UUID.randomUUID().toString()
    tokens[id] = AutocompleteSessionToken.newInstance()
    return id
  }

  fun get(id: String?): AutocompleteSessionToken? {
    if (id == null) return null
    return tokens[id]
  }

  fun clear(id: String) {
    tokens.remove(id)
  }
}
