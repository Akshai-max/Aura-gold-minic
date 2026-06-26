from app.core.kyc_profile import (
    compute_aadhaar_mobile_hash,
    parse_aadhaar_profile,
    profile_to_schema,
)


def test_parse_aadhaar_profile_coerces_numeric_pincode():
    profile = parse_aadhaar_profile(
        {
            "name": "PIRANAV",
            "date_of_birth": "01-01-1990",
            "gender": "M",
            "full_address": "Chennai, Tamil Nadu",
            "address": {"state": "Tamil Nadu", "district": "Chennai", "pincode": 600002},
        },
        "9224",
    )

    assert profile["pincode"] == "600002"
    schema = profile_to_schema(profile)
    assert schema is not None
    assert schema.pincode == "600002"
    assert schema.full_name == "PIRANAV"


def test_profile_to_schema_coerces_legacy_int_pincode():
    schema = profile_to_schema(
        {
            "full_name": "PIRANAV",
            "pincode": 600002,
            "aadhaar_last4": "9224",
        }
    )
    assert schema is not None
    assert schema.pincode == "600002"


def test_compute_aadhaar_mobile_hash_uidai_examples():
    assert (
        compute_aadhaar_mobile_hash("1234567890", "Lock@487", "XXXX XXXX 3632")
        == "f7250dc9e61759253bb741efbae306311632049154da7286e20b047bf3421a8f"
    )
    assert (
        compute_aadhaar_mobile_hash("1234567890", "Lock@487", "123412341230")
        == "0331ee76a78f1ff400f46c90e1139cf412247a96fd07b9dcf88f8e896981a53f"
    )
    assert (
        compute_aadhaar_mobile_hash("9800000002", "Abc@123", "123412341234")
        == "735c04aebc33a05af444ed41f6352b083c5a28d75ff1a26f0fe2c72bba94d7dc"
    )
