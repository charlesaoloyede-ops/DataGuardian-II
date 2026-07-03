package com.example.dataguardian

import android.content.Context
import org.json.JSONObject

/** Per-app monthly data budgets (in bytes), configured by the user and read by the background worker. */
class UsageBudgetStore(context: Context) {
    private val prefs = context.getSharedPreferences("data_guardian_budgets", Context.MODE_PRIVATE)

    fun setBudget(packageName: String, budgetBytes: Long?) {
        val json = JSONObject(prefs.getString(KEY_BUDGETS, "{}") ?: "{}")
        if (budgetBytes == null) {
            json.remove(packageName)
        } else {
            json.put(packageName, budgetBytes)
        }
        prefs.edit().putString(KEY_BUDGETS, json.toString()).apply()
    }

    fun allBudgets(): Map<String, Long> {
        val json = JSONObject(prefs.getString(KEY_BUDGETS, "{}") ?: "{}")
        return json.keys().asSequence().associateWith { json.getLong(it) }
    }

    private companion object {
        const val KEY_BUDGETS = "budgets"
    }
}
