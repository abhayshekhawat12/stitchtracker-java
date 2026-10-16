package com.stitchtrack.model;

public class SubscriptionPlan {
    private int id;
    private String planName;
    private int priceInr;
    private int clothesAdded;
    private boolean isFree;
    private int displayOrder;
    private boolean isActive;

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public String getPlanName() { return planName; }
    public void setPlanName(String v) { this.planName = v; }

    public int getPriceInr() { return priceInr; }
    public void setPriceInr(int v) { this.priceInr = v; }

    public int getClothesAdded() { return clothesAdded; }
    public void setClothesAdded(int v) { this.clothesAdded = v; }

    public boolean isFree() { return isFree; }
    public void setFree(boolean v) { this.isFree = v; }

    public int getDisplayOrder() { return displayOrder; }
    public void setDisplayOrder(int v) { this.displayOrder = v; }

    public boolean isActive() { return isActive; }
    public void setActive(boolean v) { this.isActive = v; }
}
