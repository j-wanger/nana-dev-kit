"""Unit conversion library supporting temperature, length, and weight."""

LENGTH_TO_METERS = {
    "meters": 1.0,
    "kilometers": 1000.0,
    "miles": 1609.344,
    "feet": 0.3048,
    "inches": 0.0254,
    "yards": 0.9144,
}

WEIGHT_TO_GRAMS = {
    "grams": 1.0,
    "kilograms": 1000.0,
    "pounds": 453.592,
    "ounces": 28.3495,
}


def _convert_temperature(value: float, from_unit: str, to_unit: str) -> float:
    if from_unit == to_unit:
        return value

    if from_unit == "celsius":
        celsius = value
    elif from_unit == "fahrenheit":
        celsius = (value - 32) * 5 / 9
    elif from_unit == "kelvin":
        celsius = value - 273.15
    else:
        raise ValueError(f"Unknown temperature unit: {from_unit}")

    if to_unit == "celsius":
        return celsius
    elif to_unit == "fahrenheit":
        return celsius * 9 / 5 + 32
    elif to_unit == "kelvin":
        return celsius + 273.15
    else:
        raise ValueError(f"Unknown temperature unit: {to_unit}")


def _get_unit_category(unit: str) -> str:
    if unit in LENGTH_TO_METERS:
        return "length"
    if unit in WEIGHT_TO_GRAMS:
        return "weight"
    if unit in ("celsius", "fahrenheit", "kelvin"):
        return "temperature"
    raise ValueError(f"Unknown unit: {unit}")


def convert(value: float, from_unit: str, to_unit: str) -> float:
    from_unit = from_unit.lower().strip()
    to_unit = to_unit.lower().strip()

    from_cat = _get_unit_category(from_unit)
    to_cat = _get_unit_category(to_unit)

    if from_cat != to_cat:
        raise ValueError(
            f"Cannot convert between {from_cat} ({from_unit}) "
            f"and {to_cat} ({to_unit})"
        )

    if from_cat == "temperature":
        return _convert_temperature(value, from_unit, to_unit)

    if from_cat == "length":
        table = LENGTH_TO_METERS
    else:
        table = WEIGHT_TO_GRAMS

    return value * table[to_unit] / table[from_unit]


def list_units() -> dict[str, list[str]]:
    return {
        "length": list(LENGTH_TO_METERS.keys()),
        "weight": list(WEIGHT_TO_GRAMS.keys()),
        "temperature": ["celsius", "fahrenheit", "kelvin"],
    }
