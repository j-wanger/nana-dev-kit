import pytest
from unitconv import convert, list_units


class TestLengthConversion:
    def test_meters_to_kilometers(self):
        assert convert(1000, "meters", "kilometers") == pytest.approx(1.0)

    def test_miles_to_meters(self):
        assert convert(1, "miles", "meters") == pytest.approx(1609.344)

    def test_feet_to_inches(self):
        assert convert(1, "feet", "inches") == pytest.approx(12.0)

    def test_yards_to_meters(self):
        assert convert(1, "yards", "meters") == pytest.approx(0.9144)

    def test_identity(self):
        assert convert(42, "meters", "meters") == pytest.approx(42.0)


class TestWeightConversion:
    def test_kilograms_to_grams(self):
        assert convert(1, "kilograms", "grams") == pytest.approx(1000.0)

    def test_pounds_to_ounces(self):
        assert convert(1, "pounds", "ounces") == pytest.approx(16.0, rel=0.01)

    def test_identity(self):
        assert convert(5, "grams", "grams") == pytest.approx(5.0)


class TestTemperatureConversion:
    def test_celsius_to_fahrenheit(self):
        assert convert(0, "celsius", "fahrenheit") == pytest.approx(32.0)
        assert convert(100, "celsius", "fahrenheit") == pytest.approx(212.0)

    def test_fahrenheit_to_celsius(self):
        assert convert(32, "fahrenheit", "celsius") == pytest.approx(0.0)

    def test_celsius_to_kelvin(self):
        assert convert(0, "celsius", "kelvin") == pytest.approx(273.15)

    def test_kelvin_to_celsius(self):
        assert convert(273.15, "kelvin", "celsius") == pytest.approx(0.0)

    def test_identity(self):
        assert convert(20, "celsius", "celsius") == pytest.approx(20.0)


class TestEdgeCases:
    def test_case_insensitive(self):
        assert convert(1, "Meters", "kilometers") == pytest.approx(0.001)

    def test_cross_category_raises(self):
        with pytest.raises(ValueError, match="Cannot convert"):
            convert(1, "meters", "grams")

    def test_unknown_unit_raises(self):
        with pytest.raises(ValueError, match="Unknown unit"):
            convert(1, "cubits", "meters")


class TestListUnits:
    def test_returns_all_categories(self):
        units = list_units()
        assert "length" in units
        assert "weight" in units
        assert "temperature" in units

    def test_length_units(self):
        units = list_units()
        assert "meters" in units["length"]
        assert "miles" in units["length"]
