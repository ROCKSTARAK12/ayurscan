// SkinCondition.swift
// Skin condition model - equivalent to skin_model.dart
// Location: AyurScan/Models/SkinCondition.swift

import Foundation

// MARK: - Medicine Link Model
struct MedicineLink: Identifiable, Codable, Hashable {
    let id: UUID
    let storeName: String
    let url: String
    let price: String?
    
    init(storeName: String, url: String, price: String? = nil) {
        self.id = UUID()
        self.storeName = storeName
        self.url = url
        self.price = price
    }
    
    // Codable conformance
    enum CodingKeys: String, CodingKey {
        case id, storeName, url, price
    }
}

// MARK: - Medicine Model
struct Medicine: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let type: String  // "topical", "oral", "otc"
    let description: String
    let links: [MedicineLink]
    
    init(name: String, type: String, description: String, links: [MedicineLink]) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.description = description
        self.links = links
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, type, description, links
    }
}

// MARK: - Skin Condition Model
struct SkinCondition: Identifiable, Hashable {
    let id: UUID
    let name: String
    let imageUrl: String
    let description: String
    let medicines: [Medicine]
    let category: String  // "Common", "Chronic", "Infections", "Allergic"
    
    init(name: String, imageUrl: String, description: String, medicines: [Medicine], category: String = "Common") {
        self.id = UUID()
        self.name = name
        self.imageUrl = imageUrl
        self.description = description
        self.medicines = medicines
        self.category = category
    }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: SkinCondition, rhs: SkinCondition) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Sample Data (Equivalent to your Flutter skin_model.dart)
let skinConditions: [SkinCondition] = [
    
    // 1. Acne
    SkinCondition(
        name: "Acne",
        imageUrl: "https://picsum.photos/seed/acne/500/500",
        description: """
        Acne is a chronic skin condition that arises when the pores of the skin become clogged with oil, dead skin cells, and bacteria. It manifests as pimples, blackheads, whiteheads, or cysts, and most commonly appears on the face, back, and shoulders.
        
        Causes include hormonal imbalances, stress, poor diet, improper skin hygiene, and excessive use of oily or comedogenic products.
        
        ✅ Precautions: Maintain a regular skincare routine with non-comedogenic products, avoid touching the face frequently, cleanse your face twice daily, and use sunscreen.
        
        💊 Treatment: Over-the-counter products with salicylic acid or benzoyl peroxide, prescribed topical or oral antibiotics, retinoids, hormone therapy, and in severe cases, isotretinoin.
        """,
        medicines: [
            Medicine(
                name: "Benzoyl Peroxide Gel",
                type: "topical",
                description: "Effective for killing acne bacteria and reducing inflammation",
                links: [
                    MedicineLink(storeName: "Amazon India", url: "https://www.amazon.in/s?k=benzoyl+peroxide+gel+acne"),
                    MedicineLink(storeName: "PharmEasy", url: "https://pharmeasy.in/search/benzoyl-peroxide"),
                    MedicineLink(storeName: "Apollo Pharmacy", url: "https://www.apollopharmacy.in/search-medicines/benzoyl-peroxide")
                ]
            ),
            Medicine(
                name: "Salicylic Acid Face Wash",
                type: "topical",
                description: "Helps unclog pores and reduce blackheads",
                links: [
                    MedicineLink(storeName: "Flipkart Health+", url: "https://healthplus.flipkart.com/search?q=salicylic%20acid%20face%20wash"),
                    MedicineLink(storeName: "Netmeds", url: "https://www.netmeds.com/catalogsearch/result/?q=salicylic+acid+face+wash"),
                    MedicineLink(storeName: "MedPlus", url: "https://www.medplusmart.com/search?name=salicylic+acid")
                ]
            ),
            Medicine(
                name: "Tretinoin Cream",
                type: "topical",
                description: "Prescription retinoid for severe acne treatment",
                links: [
                    MedicineLink(storeName: "PharmEasy", url: "https://pharmeasy.in/search/tretinoin-cream"),
                    MedicineLink(storeName: "Apollo Pharmacy", url: "https://www.apollopharmacy.in/search-medicines/tretinoin")
                ]
            )
        ],
        category: "Common"
    ),
    
    // 2. Eczema
    SkinCondition(
        name: "Eczema",
        imageUrl: "https://picsum.photos/seed/eczema/500/500",
        description: """
        Eczema, or atopic dermatitis, is a chronic inflammatory skin disorder that leads to dry, itchy, red, and inflamed patches of skin. It typically begins in childhood but may persist into adulthood.
        
        Common triggers include allergens, harsh soaps, detergents, temperature extremes, and stress.
        
        ✅ Precautions: Use fragrance-free moisturizers regularly, wear breathable fabrics, avoid scratching, and identify and avoid known irritants.
        
        💊 Treatment: Includes topical corticosteroids, antihistamines, emollient creams, and in some cases, immunosuppressive drugs or phototherapy.
        """,
        medicines: [
            Medicine(
                name: "Hydrocortisone Cream",
                type: "topical",
                description: "Mild corticosteroid for reducing inflammation and itching",
                links: [
                    MedicineLink(storeName: "Amazon India", url: "https://www.amazon.in/s?k=hydrocortisone+cream+eczema"),
                    MedicineLink(storeName: "PharmEasy", url: "https://pharmeasy.in/search/hydrocortisone-cream"),
                    MedicineLink(storeName: "NetMeds", url: "https://www.netmeds.com/catalogsearch/result/?q=hydrocortisone+cream")
                ]
            ),
            Medicine(
                name: "Cetirizine Tablets",
                type: "oral",
                description: "Antihistamine to reduce itching and allergic reactions",
                links: [
                    MedicineLink(storeName: "Apollo Pharmacy", url: "https://www.apollopharmacy.in/search-medicines/cetirizine"),
                    MedicineLink(storeName: "Flipkart Health+", url: "https://healthplus.flipkart.com/search?q=cetirizine%20tablets"),
                    MedicineLink(storeName: "Truemeds", url: "https://www.truemeds.in/search?name=cetirizine")
                ]
            ),
            Medicine(
                name: "Moisturizing Emollient Cream",
                type: "topical",
                description: "Daily moisturizer to prevent skin dryness",
                links: [
                    MedicineLink(storeName: "MedPlus", url: "https://www.medplusmart.com/search?name=emollient+cream"),
                    MedicineLink(storeName: "Amazon India", url: "https://www.amazon.in/s?k=emollient+cream+dry+skin")
                ]
            )
        ],
        category: "Chronic"
    ),
    
    // 3. Psoriasis
    SkinCondition(
        name: "Psoriasis",
        imageUrl: "https://picsum.photos/seed/psoriasis/500/500",
        description: """
        Psoriasis is a long-term autoimmune skin disease that speeds up the life cycle of skin cells, causing them to build up rapidly on the surface. This leads to thick, red patches covered with silvery scales.
        
        Genetic predisposition, stress, cold weather, skin injury, and certain medications can trigger symptoms.
        
        ✅ Precautions: Keep skin moisturized, avoid harsh skin products, manage stress, and maintain a healthy lifestyle.
        
        💊 Treatment: Includes topical treatments like coal tar and corticosteroids, phototherapy, and systemic medications.
        """,
        medicines: [
            Medicine(
                name: "Coal Tar Shampoo",
                type: "topical",
                description: "Effective for scalp psoriasis treatment",
                links: [
                    MedicineLink(storeName: "PharmEasy", url: "https://pharmeasy.in/search/coal-tar-shampoo"),
                    MedicineLink(storeName: "Apollo Pharmacy", url: "https://www.apollopharmacy.in/search-medicines/coal-tar"),
                    MedicineLink(storeName: "Amazon India", url: "https://www.amazon.in/s?k=coal+tar+shampoo+psoriasis")
                ]
            ),
            Medicine(
                name: "Clobetasol Propionate Cream",
                type: "topical",
                description: "Strong corticosteroid for severe psoriasis patches",
                links: [
                    MedicineLink(storeName: "NetMeds", url: "https://www.netmeds.com/catalogsearch/result/?q=clobetasol+propionate"),
                    MedicineLink(storeName: "PharmEasy", url: "https://pharmeasy.in/search/clobetasol-propionate")
                ]
            )
        ],
        category: "Chronic"
    ),
    
    // 4. Rosacea
    SkinCondition(
        name: "Rosacea",
        imageUrl: "https://picsum.photos/seed/rosacea/500/500",
        description: """
        Rosacea is a chronic skin condition primarily affecting the face, causing redness, visible blood vessels, swelling, and sometimes acne-like breakouts.
        
        Triggers include sun exposure, spicy foods, alcohol, hot beverages, and emotional stress.
        
        ✅ Precautions: Use sunscreen daily, avoid known triggers, use gentle skincare, and avoid exfoliating products.
        
        💊 Treatment: Topical antibiotics such as metronidazole, oral tetracyclines, laser therapy for visible blood vessels.
        """,
        medicines: [
            Medicine(
                name: "Metronidazole Gel",
                type: "topical",
                description: "Topical antibiotic for reducing rosacea inflammation",
                links: [
                    MedicineLink(storeName: "PharmEasy", url: "https://pharmeasy.in/search/metronidazole-gel"),
                    MedicineLink(storeName: "Apollo Pharmacy", url: "https://www.apollopharmacy.in/search-medicines/metronidazole"),
                    MedicineLink(storeName: "NetMeds", url: "https://www.netmeds.com/catalogsearch/result/?q=metronidazole+gel")
                ]
            ),
            Medicine(
                name: "Gentle Sunscreen SPF 30+",
                type: "topical",
                description: "Daily sun protection to prevent rosacea flare-ups",
                links: [
                    MedicineLink(storeName: "Amazon India", url: "https://www.amazon.in/s?k=sunscreen+sensitive+skin+spf+30"),
                    MedicineLink(storeName: "Apollo Pharmacy", url: "https://www.apollopharmacy.in/search-medicines/sunscreen")
                ]
            )
        ],
        category: "Chronic"
    ),
    
    // 5. Vitiligo
    SkinCondition(
        name: "Vitiligo",
        imageUrl: "https://picsum.photos/seed/vitiligo/500/500",
        description: """
        Vitiligo is a condition in which pigment-producing cells (melanocytes) are destroyed, resulting in white patches on the skin. The exact cause is unknown but is believed to be autoimmune.
        
        It is non-contagious and may be associated with thyroid disorders.
        
        ✅ Precautions: Use sunscreen to prevent sunburn on depigmented areas, avoid tanning, and wear protective clothing.
        
        💊 Treatment: Includes topical corticosteroids, calcineurin inhibitors, light therapy (narrowband UVB).
        """,
        medicines: [
            Medicine(
                name: "Tacrolimus Ointment",
                type: "topical",
                description: "Calcineurin inhibitor for vitiligo treatment",
                links: [
                    MedicineLink(storeName: "PharmEasy", url: "https://pharmeasy.in/search/tacrolimus-ointment"),
                    MedicineLink(storeName: "NetMeds", url: "https://www.netmeds.com/catalogsearch/result/?q=tacrolimus"),
                    MedicineLink(storeName: "Apollo Pharmacy", url: "https://www.apollopharmacy.in/search-medicines/tacrolimus")
                ]
            ),
            Medicine(
                name: "High SPF Sunscreen",
                type: "topical",
                description: "Essential protection for depigmented areas",
                links: [
                    MedicineLink(storeName: "Amazon India", url: "https://www.amazon.in/s?k=high+spf+sunscreen+50"),
                    MedicineLink(storeName: "MedPlus", url: "https://www.medplusmart.com/search?name=sunscreen+spf+50")
                ]
            )
        ],
        category: "Chronic"
    ),
    
    // 6. Fungal Infections
    SkinCondition(
        name: "Fungal Infections",
        imageUrl: "https://picsum.photos/seed/fungal/500/500",
        description: """
        Fungal infections are caused by fungi thriving in warm, moist environments and include athlete's foot, ringworm, jock itch, and candidiasis.
        
        They cause itching, redness, flaking, and in some cases, blisters.
        
        ✅ Precautions: Keep skin clean and dry, wear breathable clothing, avoid sharing towels or shoes.
        
        💊 Treatment: Topical antifungal creams like clotrimazole, terbinafine, or miconazole.
        """,
        medicines: [
            Medicine(
                name: "Clotrimazole Cream",
                type: "topical",
                description: "Broad-spectrum antifungal for most fungal infections",
                links: [
                    MedicineLink(storeName: "Amazon India", url: "https://www.amazon.in/s?k=clotrimazole+cream+antifungal"),
                    MedicineLink(storeName: "PharmEasy", url: "https://pharmeasy.in/search/clotrimazole-cream"),
                    MedicineLink(storeName: "Apollo Pharmacy", url: "https://www.apollopharmacy.in/search-medicines/clotrimazole")
                ]
            ),
            Medicine(
                name: "Terbinafine Cream",
                type: "topical",
                description: "Effective for athlete's foot and ringworm",
                links: [
                    MedicineLink(storeName: "NetMeds", url: "https://www.netmeds.com/catalogsearch/result/?q=terbinafine+cream"),
                    MedicineLink(storeName: "Flipkart Health+", url: "https://healthplus.flipkart.com/search?q=terbinafine%20cream"),
                    MedicineLink(storeName: "MedPlus", url: "https://www.medplusmart.com/search?name=terbinafine")
                ]
            ),
            Medicine(
                name: "Fluconazole Tablets",
                type: "oral",
                description: "Oral antifungal for severe or widespread infections",
                links: [
                    MedicineLink(storeName: "PharmEasy", url: "https://pharmeasy.in/search/fluconazole-tablets"),
                    MedicineLink(storeName: "Truemeds", url: "https://www.truemeds.in/search?name=fluconazole"),
                    MedicineLink(storeName: "Apollo Pharmacy", url: "https://www.apollopharmacy.in/search-medicines/fluconazole")
                ]
            )
        ],
        category: "Infections"
    ),
    
    // 7. Hives (Urticaria)
    SkinCondition(
        name: "Hives",
        imageUrl: "https://picsum.photos/seed/hives/500/500",
        description: """
        Hives, or urticaria, are red, raised, and itchy welts on the skin that appear suddenly and can vary in size and shape. They are usually caused by allergic reactions.
        
        ✅ Precautions: Avoid known allergens, wear loose-fitting clothes, and stay in cool environments.
        
        💊 Treatment: Antihistamines to relieve itching and swelling, corticosteroids in severe cases.
        """,
        medicines: [
            Medicine(
                name: "Loratadine Tablets",
                type: "oral",
                description: "Non-drowsy antihistamine for hives relief",
                links: [
                    MedicineLink(storeName: "Amazon India", url: "https://www.amazon.in/s?k=loratadine+tablets+10mg"),
                    MedicineLink(storeName: "PharmEasy", url: "https://pharmeasy.in/search/loratadine"),
                    MedicineLink(storeName: "Apollo Pharmacy", url: "https://www.apollopharmacy.in/search-medicines/loratadine")
                ]
            ),
            Medicine(
                name: "Calamine Lotion",
                type: "topical",
                description: "Soothing lotion for itching and irritation",
                links: [
                    MedicineLink(storeName: "NetMeds", url: "https://www.netmeds.com/catalogsearch/result/?q=calamine+lotion"),
                    MedicineLink(storeName: "MedPlus", url: "https://www.medplusmart.com/search?name=calamine")
                ]
            )
        ],
        category: "Allergic"
    ),
    
    // 8. Warts
    SkinCondition(
        name: "Warts",
        imageUrl: "https://picsum.photos/seed/warts/500/500",
        description: """
        Warts are small, rough, and grainy skin growths caused by the human papillomavirus (HPV). They often appear on hands, feet, or genitals.
        
        ✅ Precautions: Do not pick at warts, avoid sharing personal items, keep affected areas dry.
        
        💊 Treatment: Over-the-counter salicylic acid products, cryotherapy (freezing), laser therapy.
        """,
        medicines: [
            Medicine(
                name: "Salicylic Acid Solution",
                type: "topical",
                description: "Over-the-counter wart removal treatment",
                links: [
                    MedicineLink(storeName: "Amazon India", url: "https://www.amazon.in/s?k=salicylic+acid+wart+removal"),
                    MedicineLink(storeName: "PharmEasy", url: "https://pharmeasy.in/search/salicylic-acid-solution"),
                    MedicineLink(storeName: "Apollo Pharmacy", url: "https://www.apollopharmacy.in/search-medicines/salicylic-acid")
                ]
            ),
            Medicine(
                name: "Cryotherapy Kit",
                type: "otc",
                description: "At-home freezing treatment for warts",
                links: [
                    MedicineLink(storeName: "Amazon India", url: "https://www.amazon.in/s?k=wart+removal+cryotherapy+kit"),
                    MedicineLink(storeName: "MedPlus", url: "https://www.medplusmart.com/search?name=wart+removal")
                ]
            )
        ],
        category: "Infections"
    ),
    
    // 9. Melasma
    SkinCondition(
        name: "Melasma",
        imageUrl: "https://picsum.photos/seed/melasma/500/500",
        description: """
        Melasma is a common skin condition that results in brown or grayish-brown patches, mainly on the face. It is more common in women and can be triggered by hormonal changes and sun exposure.
        
        ✅ Precautions: Avoid direct sun exposure, wear wide-brimmed hats, and use high-SPF sunscreen daily.
        
        💊 Treatment: Topical skin-lightening agents like hydroquinone, tretinoin, azelaic acid.
        """,
        medicines: [
            Medicine(
                name: "Hydroquinone Cream 2%",
                type: "topical",
                description: "Skin lightening agent for melasma treatment",
                links: [
                    MedicineLink(storeName: "PharmEasy", url: "https://pharmeasy.in/search/hydroquinone-cream"),
                    MedicineLink(storeName: "Apollo Pharmacy", url: "https://www.apollopharmacy.in/search-medicines/hydroquinone"),
                    MedicineLink(storeName: "NetMeds", url: "https://www.netmeds.com/catalogsearch/result/?q=hydroquinone+cream")
                ]
            ),
            Medicine(
                name: "Azelaic Acid Cream",
                type: "topical",
                description: "Gentle skin lightening and anti-inflammatory agent",
                links: [
                    MedicineLink(storeName: "Amazon India", url: "https://www.amazon.in/s?k=azelaic+acid+cream+melasma"),
                    MedicineLink(storeName: "MedPlus", url: "https://www.medplusmart.com/search?name=azelaic+acid")
                ]
            )
        ],
        category: "Common"
    ),
    
    // 10. Impetigo
    SkinCondition(
        name: "Impetigo",
        imageUrl: "https://picsum.photos/seed/impetigo/500/500",
        description: """
        Impetigo is a highly contagious bacterial skin infection, most common in children, that causes red sores, usually around the nose and mouth. These sores burst and develop honey-colored crusts.
        
        ✅ Precautions: Maintain hygiene, wash hands frequently, avoid touching sores, and disinfect surfaces.
        
        💊 Treatment: Topical antibiotic creams such as mupirocin, oral antibiotics in more widespread cases.
        """,
        medicines: [
            Medicine(
                name: "Mupirocin Ointment",
                type: "topical",
                description: "Topical antibiotic specifically effective against impetigo",
                links: [
                    MedicineLink(storeName: "PharmEasy", url: "https://pharmeasy.in/search/mupirocin-ointment"),
                    MedicineLink(storeName: "Apollo Pharmacy", url: "https://www.apollopharmacy.in/search-medicines/mupirocin"),
                    MedicineLink(storeName: "NetMeds", url: "https://www.netmeds.com/catalogsearch/result/?q=mupirocin+ointment")
                ]
            ),
            Medicine(
                name: "Antiseptic Solution",
                type: "topical",
                description: "For cleaning and disinfecting affected areas",
                links: [
                    MedicineLink(storeName: "Amazon India", url: "https://www.amazon.in/s?k=antiseptic+solution+wound+care"),
                    MedicineLink(storeName: "Apollo Pharmacy", url: "https://www.apollopharmacy.in/search-medicines/antiseptic")
                ]
            )
        ],
        category: "Infections"
    )
]
