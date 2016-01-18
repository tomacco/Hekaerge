package com.innoquant.mocaapp;

public class HkLocation {
    private String mIdentifier;
    private Double mLatitude;
    private Double mLongitude;
    private int mFloor;
    private Double mRadius;

    public HkLocation(String id,
                      Double latitude,
                      Double longitude,
                      int floor,
                      Double radius){
        mIdentifier = id;
        mLatitude = latitude;
        mLongitude = longitude;
        mFloor = floor;
        mRadius = radius;
    }

    public Double getRadius() {
        return mRadius;
    }

    public String getId() {
        return mIdentifier;
    }

    public Double getLatitude() {
        return mLatitude;
    }

    public Double getLongitude() {
        return mLongitude;
    }

    public int getFloor() {
        return mFloor;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;

        HkLocation that = (HkLocation) o;

        if (mFloor != that.mFloor) return false;
        if (!mLatitude.equals(that.mLatitude)) return false;
        if (!mLongitude.equals(that.mLongitude)) return false;
        return mRadius.equals(that.mRadius);

    }

    @Override
    public int hashCode() {
        int result = mLatitude.hashCode();
        result = 31 * result + mLongitude.hashCode();
        result = 31 * result + mFloor;
        result = 31 * result + mRadius.hashCode();
        return result;
    }
}