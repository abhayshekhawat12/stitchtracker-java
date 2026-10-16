package com.stitchtrack.util;

import java.util.Map;
import java.util.Set;

/**
 * Single source of truth for item credit rates.
 *
 * Normal items  = 1 credit per item.
 * Large items   = 3 credits per item.
 *
 * "Large" is defined by requiring extra washing, water, and processing time.
 */
public final class CreditRules {

    private CreditRules() {}

    /** Items that cost 3 credits each. All others cost 1 credit. */
    public static final Set<String> LARGE_ITEMS = Set.of(
            "Blanket", "Bedsheet", "Quilt", "Razai", "Comforter", "Duvet"
    );

    /**
     * Returns the credit rate (1 or 3) for the given item category name.
     * Case-sensitive – must match the exact strings used in CATS array.
     */
    public static int rateFor(String category) {
        return LARGE_ITEMS.contains(category) ? 3 : 1;
    }

    /**
     * Calculates the total credits consumed by an item map
     * {category -> quantity}, applying credit rates.
     */
    public static int totalCredits(Map<String, Integer> items) {
        int total = 0;
        for (var e : items.entrySet()) {
            if (e.getValue() != null && e.getValue() > 0) {
                total += e.getValue() * rateFor(e.getKey());
            }
        }
        return total;
    }

    /** Total physical item count (ignoring credit rates). */
    public static int totalItems(Map<String, Integer> items) {
        return items.values().stream().filter(v -> v != null).mapToInt(Integer::intValue).sum();
    }

    public static boolean isLarge(String category) {
        return LARGE_ITEMS.contains(category);
    }
}
