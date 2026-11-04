#!/usr/bin/env python3
import hashlib
import os
import sys

def gen_id(name: str) -> str:
    """Generate deterministic 24-hex-char ID from a string."""
    h = hashlib.sha256(name.encode('utf-8')).hexdigest()
    return h[:24].upper()

def main():
    repo_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    proj_dir = os.path.join(repo_root, "AssessYourself.xcodeproj")
    os.makedirs(proj_dir, exist_ok=True)
    shared_schemes_dir = os.path.join(proj_dir, "xcshareddata", "xcschemes")
    os.makedirs(shared_schemes_dir, exist_ok=True)

    app_sources = [
        "src/App/AssessYourselfApp.swift",
        "src/Models/ArchetypeProfile.swift",
        "src/Models/AssessmentDimension.swift",
        "src/Models/AssessmentQuestion.swift",
        "src/Models/QuestionType.swift",
        "src/Models/AssessmentCatalog.swift",
        "src/Models/AssessmentRecord.swift",
        "src/ViewModels/AssessmentViewModelProtocol.swift",
        "src/ViewModels/AssessmentViewModel.swift",
        "src/Views/Screens/ComponentShowcaseView.swift",
        "src/Views/Screens/AssessmentQuestionContainerView.swift",
        "src/Views/Screens/AssessmentFlowView.swift",
        "src/Views/Components/Color+Adaptive.swift",
        "src/Views/Components/MultiSelectChipGrid.swift",
        "src/Views/Components/LikertSliderCard.swift",
        "src/Views/Components/ShortTextPromptCard.swift",
        "src/Views/Components/ChoiceOptionButton.swift",
        "src/Views/Components/TactileButtonStyle.swift",
        "src/Views/Components/DesignTokens.swift",
        "src/Services/CatalogLoaderProtocol.swift",
        "src/Services/EvaluationEngineProtocol.swift",
        "src/Services/HapticFeedbackService.swift",
    ]

    app_resources = [
        "src/Resources/assessment_catalog.json",
    ]

    test_sources = [
        "src/Tests/CatalogTests.swift",
        "src/Tests/ColorTokenTests.swift",
        "src/Tests/EvaluationEngineTests.swift",
        "src/Tests/UIComponentTests.swift",
        "src/Tests/AssessmentViewModelTests.swift",
        "src/Tests/HapticFeedbackServiceTests.swift",
    ]

    ui_test_sources = [
        "ui-tests/AssessYourselfUITests.swift",
    ]

    # Target & Product IDs
    proj_id = gen_id("PROJECT_AssessYourself")
    main_group_id = gen_id("GROUP_Main")
    products_group_id = gen_id("GROUP_Products")
    src_group_id = gen_id("GROUP_src")
    ui_tests_group_id = gen_id("GROUP_ui_tests")
    app_group_id = gen_id("GROUP_App")
    models_group_id = gen_id("GROUP_Models")
    viewmodels_group_id = gen_id("GROUP_ViewModels")
    services_group_id = gen_id("GROUP_Services")
    views_group_id = gen_id("GROUP_Views")
    components_group_id = gen_id("GROUP_Components")
    screens_group_id = gen_id("GROUP_Screens")
    resources_group_id = gen_id("GROUP_Resources")
    tests_group_id = gen_id("GROUP_Tests")

    app_target_id = gen_id("TARGET_AssessYourself")
    app_product_id = gen_id("PRODUCT_AssessYourself_App")
    test_target_id = gen_id("TARGET_AssessYourselfTests")
    test_product_id = gen_id("PRODUCT_AssessYourself_Test")
    ui_test_target_id = gen_id("TARGET_AssessYourselfUITests")
    ui_test_product_id = gen_id("PRODUCT_AssessYourself_UITest")

    target_dep_id = gen_id("DEP_AssessYourselfTests_AssessYourself")
    container_item_id = gen_id("CONTAINER_AssessYourself")
    ui_target_dep_id = gen_id("DEP_AssessYourselfUITests_AssessYourself")
    ui_container_item_id = gen_id("CONTAINER_AssessYourself_UI")

    app_sources_phase_id = gen_id("PHASE_App_Sources")
    app_resources_phase_id = gen_id("PHASE_App_Resources")
    app_frameworks_phase_id = gen_id("PHASE_App_Frameworks")

    test_sources_phase_id = gen_id("PHASE_Test_Sources")
    test_resources_phase_id = gen_id("PHASE_Test_Resources")
    test_frameworks_phase_id = gen_id("PHASE_Test_Frameworks")

    ui_test_sources_phase_id = gen_id("PHASE_UITest_Sources")
    ui_test_resources_phase_id = gen_id("PHASE_UITest_Resources")
    ui_test_frameworks_phase_id = gen_id("PHASE_UITest_Frameworks")

    proj_cfg_list_id = gen_id("CFGLIST_Project")
    proj_debug_cfg_id = gen_id("CFG_Project_Debug")
    proj_release_cfg_id = gen_id("CFG_Project_Release")

    app_cfg_list_id = gen_id("CFGLIST_App")
    app_debug_cfg_id = gen_id("CFG_App_Debug")
    app_release_cfg_id = gen_id("CFG_App_Release")

    test_cfg_list_id = gen_id("CFGLIST_Test")
    test_debug_cfg_id = gen_id("CFG_Test_Debug")
    test_release_cfg_id = gen_id("CFG_Test_Release")

    ui_test_cfg_list_id = gen_id("CFGLIST_UITest")
    ui_test_debug_cfg_id = gen_id("CFG_UITest_Debug")
    ui_test_release_cfg_id = gen_id("CFG_UITest_Release")

    # Map files to fileref and buildfile
    filerefs = {}
    buildfiles = {}

    all_files = app_sources + app_resources + test_sources + ui_test_sources
    for path in all_files:
        fref = gen_id("FILEREF_" + path)
        bf_app = gen_id("BUILDFILE_APP_" + path)
        bf_test = gen_id("BUILDFILE_TEST_" + path)
        bf_uitest = gen_id("BUILDFILE_UITEST_" + path)
        filerefs[path] = fref
        buildfiles[path] = {"app": bf_app, "test": bf_test, "uitest": bf_uitest}

    pbx = []
    pbx.append("// !$*UTF8*$!")
    pbx.append("{")
    pbx.append("\tarchiveVersion = 1;")
    pbx.append("\tclasses = {")
    pbx.append("\t};")
    pbx.append("\tobjectVersion = 56;")
    pbx.append("\tobjects = {")

    # PBXBuildFile section
    pbx.append("\n/* Begin PBXBuildFile section */")
    for path in app_sources:
        bf = buildfiles[path]["app"]
        fref = filerefs[path]
        pbx.append(f"\t\t{bf} /* {path} in Sources */ = {{isa = PBXBuildFile; fileRef = {fref} /* {os.path.basename(path)} */; }};")
    for path in app_resources:
        bf = buildfiles[path]["app"]
        fref = filerefs[path]
        pbx.append(f"\t\t{bf} /* {path} in Resources */ = {{isa = PBXBuildFile; fileRef = {fref} /* {os.path.basename(path)} */; }};")
    for path in test_sources:
        bf = buildfiles[path]["test"]
        fref = filerefs[path]
        pbx.append(f"\t\t{bf} /* {path} in Sources */ = {{isa = PBXBuildFile; fileRef = {fref} /* {os.path.basename(path)} */; }};")
    for path in ui_test_sources:
        bf = buildfiles[path]["uitest"]
        fref = filerefs[path]
        pbx.append(f"\t\t{bf} /* {path} in Sources */ = {{isa = PBXBuildFile; fileRef = {fref} /* {os.path.basename(path)} */; }};")
    pbx.append("/* End PBXBuildFile section */")

    # PBXContainerItemProxy
    pbx.append("\n/* Begin PBXContainerItemProxy section */")
    pbx.append(f"\t\t{container_item_id} /* PBXContainerItemProxy */ = {{")
    pbx.append(f"\t\t\tisa = PBXContainerItemProxy;")
    pbx.append(f"\t\t\tcontainerPortal = {proj_id} /* Project object */;")
    pbx.append(f"\t\t\tproxyType = 1;")
    pbx.append(f"\t\t\tremoteGlobalIDString = {app_target_id};")
    pbx.append(f"\t\t\tremoteInfo = AssessYourself;")
    pbx.append(f"\t\t}};")
    pbx.append(f"\t\t{ui_container_item_id} /* PBXContainerItemProxy */ = {{")
    pbx.append(f"\t\t\tisa = PBXContainerItemProxy;")
    pbx.append(f"\t\t\tcontainerPortal = {proj_id} /* Project object */;")
    pbx.append(f"\t\t\tproxyType = 1;")
    pbx.append(f"\t\t\tremoteGlobalIDString = {app_target_id};")
    pbx.append(f"\t\t\tremoteInfo = AssessYourself;")
    pbx.append(f"\t\t}};")
    pbx.append("/* End PBXContainerItemProxy section */")

    # PBXFileReference section
    pbx.append("\n/* Begin PBXFileReference section */")
    pbx.append(f"\t\t{app_product_id} /* AssessYourself.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = AssessYourself.app; sourceTree = BUILT_PRODUCTS_DIR; }};")
    pbx.append(f"\t\t{test_product_id} /* AssessYourselfTests.xctest */ = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = AssessYourselfTests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};")
    pbx.append(f"\t\t{ui_test_product_id} /* AssessYourselfUITests.xctest */ = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = AssessYourselfUITests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};")

    for path in all_files:
        fref = filerefs[path]
        filename = os.path.basename(path)
        last_known_type = "sourcecode.swift" if path.endswith(".swift") else "text.json"
        pbx.append(f"\t\t{fref} /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = {last_known_type}; path = \"{filename}\"; sourceTree = \"<group>\"; }};")
    pbx.append("/* End PBXFileReference section */")

    # PBXFrameworksBuildPhase
    pbx.append("\n/* Begin PBXFrameworksBuildPhase section */")
    for phase_id in [app_frameworks_phase_id, test_frameworks_phase_id, ui_test_frameworks_phase_id]:
        pbx.append(f"\t\t{phase_id} /* Frameworks */ = {{")
        pbx.append("\t\t\tisa = PBXFrameworksBuildPhase;")
        pbx.append("\t\t\tbuildActionMask = 2147483647;")
        pbx.append("\t\t\tfiles = (")
        pbx.append("\t\t\t);")
        pbx.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
        pbx.append("\t\t};")
    pbx.append("/* End PBXFrameworksBuildPhase section */")

    # PBXGroup section
    pbx.append("\n/* Begin PBXGroup section */")
    pbx.append(f"\t\t{main_group_id} = {{")
    pbx.append("\t\t\tisa = PBXGroup;")
    pbx.append("\t\t\tchildren = (")
    pbx.append(f"\t\t\t\t{src_group_id} /* src */,")
    pbx.append(f"\t\t\t\t{ui_tests_group_id} /* ui-tests */,")
    pbx.append(f"\t\t\t\t{products_group_id} /* Products */,")
    pbx.append("\t\t\t);")
    pbx.append("\t\t\tsourceTree = \"<group>\";")
    pbx.append("\t\t};")

    pbx.append(f"\t\t{products_group_id} /* Products */ = {{")
    pbx.append("\t\t\tisa = PBXGroup;")
    pbx.append("\t\t\tchildren = (")
    pbx.append(f"\t\t\t\t{app_product_id} /* AssessYourself.app */,")
    pbx.append(f"\t\t\t\t{test_product_id} /* AssessYourselfTests.xctest */,")
    pbx.append(f"\t\t\t\t{ui_test_product_id} /* AssessYourselfUITests.xctest */,")
    pbx.append("\t\t\t);")
    pbx.append("\t\t\tname = Products;")
    pbx.append("\t\t\tsourceTree = \"<group>\";")
    pbx.append("\t\t};")

    pbx.append(f"\t\t{ui_tests_group_id} /* ui-tests */ = {{")
    pbx.append("\t\t\tisa = PBXGroup;")
    pbx.append("\t\t\tchildren = (")
    for f in ui_test_sources:
        pbx.append(f"\t\t\t\t{filerefs[f]} /* {os.path.basename(f)} */,")
    pbx.append("\t\t\t);")
    pbx.append("\t\t\tpath = \"ui-tests\";")
    pbx.append("\t\t\tsourceTree = \"<group>\";")
    pbx.append("\t\t};")

    pbx.append(f"\t\t{src_group_id} /* src */ = {{")
    pbx.append("\t\t\tisa = PBXGroup;")
    pbx.append("\t\t\tchildren = (")
    pbx.append(f"\t\t\t\t{app_group_id} /* App */,")
    pbx.append(f"\t\t\t\t{models_group_id} /* Models */,")
    pbx.append(f"\t\t\t\t{viewmodels_group_id} /* ViewModels */,")
    pbx.append(f"\t\t\t\t{services_group_id} /* Services */,")
    pbx.append(f"\t\t\t\t{views_group_id} /* Views */,")
    pbx.append(f"\t\t\t\t{resources_group_id} /* Resources */,")
    pbx.append(f"\t\t\t\t{tests_group_id} /* Tests */,")
    pbx.append("\t\t\t);")
    pbx.append("\t\t\tpath = src;")
    pbx.append("\t\t\tsourceTree = \"<group>\";")
    pbx.append("\t\t};")

    # Subgroups
    pbx.append(f"\t\t{app_group_id} /* App */ = {{")
    pbx.append("\t\t\tisa = PBXGroup;")
    pbx.append("\t\t\tchildren = (")
    pbx.append(f"\t\t\t\t{filerefs['src/App/AssessYourselfApp.swift']} /* AssessYourselfApp.swift */,")
    pbx.append("\t\t\t);")
    pbx.append("\t\t\tpath = App;")
    pbx.append("\t\t\tsourceTree = \"<group>\";")
    pbx.append("\t\t};")

    pbx.append(f"\t\t{models_group_id} /* Models */ = {{")
    pbx.append("\t\t\tisa = PBXGroup;")
    pbx.append("\t\t\tchildren = (")
    for f in ["ArchetypeProfile.swift", "AssessmentDimension.swift", "AssessmentQuestion.swift", "QuestionType.swift", "AssessmentCatalog.swift", "AssessmentRecord.swift"]:
        pbx.append(f"\t\t\t\t{filerefs['src/Models/' + f]} /* {f} */,")
    pbx.append("\t\t\t);")
    pbx.append("\t\t\tpath = Models;")
    pbx.append("\t\t\tsourceTree = \"<group>\";")
    pbx.append("\t\t};")

    pbx.append(f"\t\t{viewmodels_group_id} /* ViewModels */ = {{")
    pbx.append("\t\t\tisa = PBXGroup;")
    pbx.append("\t\t\tchildren = (")
    for f in ["AssessmentViewModelProtocol.swift", "AssessmentViewModel.swift"]:
        pbx.append(f"\t\t\t\t{filerefs['src/ViewModels/' + f]} /* {f} */,")
    pbx.append("\t\t\t);")
    pbx.append("\t\t\tpath = ViewModels;")
    pbx.append("\t\t\tsourceTree = \"<group>\";")
    pbx.append("\t\t};")

    pbx.append(f"\t\t{services_group_id} /* Services */ = {{")
    pbx.append("\t\t\tisa = PBXGroup;")
    pbx.append("\t\t\tchildren = (")
    for f in ["CatalogLoaderProtocol.swift", "EvaluationEngineProtocol.swift", "HapticFeedbackService.swift"]:
        pbx.append(f"\t\t\t\t{filerefs['src/Services/' + f]} /* {f} */,")
    pbx.append("\t\t\t);")
    pbx.append("\t\t\tpath = Services;")
    pbx.append("\t\t\tsourceTree = \"<group>\";")
    pbx.append("\t\t};")

    pbx.append(f"\t\t{views_group_id} /* Views */ = {{")
    pbx.append("\t\t\tisa = PBXGroup;")
    pbx.append("\t\t\tchildren = (")
    pbx.append(f"\t\t\t\t{components_group_id} /* Components */,")
    pbx.append(f"\t\t\t\t{screens_group_id} /* Screens */,")
    pbx.append("\t\t\t);")
    pbx.append("\t\t\tpath = Views;")
    pbx.append("\t\t\tsourceTree = \"<group>\";")
    pbx.append("\t\t};")

    pbx.append(f"\t\t{components_group_id} /* Components */ = {{")
    pbx.append("\t\t\tisa = PBXGroup;")
    pbx.append("\t\t\tchildren = (")
    for f in ["ChoiceOptionButton.swift", "Color+Adaptive.swift", "DesignTokens.swift", "LikertSliderCard.swift", "MultiSelectChipGrid.swift", "ShortTextPromptCard.swift", "TactileButtonStyle.swift"]:
        pbx.append(f"\t\t\t\t{filerefs['src/Views/Components/' + f]} /* {f} */,")
    pbx.append("\t\t\t);")
    pbx.append("\t\t\tpath = Components;")
    pbx.append("\t\t\tsourceTree = \"<group>\";")
    pbx.append("\t\t};")

    pbx.append(f"\t\t{screens_group_id} /* Screens */ = {{")
    pbx.append("\t\t\tisa = PBXGroup;")
    pbx.append("\t\t\tchildren = (")
    for f in ["ComponentShowcaseView.swift", "AssessmentQuestionContainerView.swift", "AssessmentFlowView.swift"]:
        pbx.append(f"\t\t\t\t{filerefs['src/Views/Screens/' + f]} /* {f} */,")
    pbx.append("\t\t\t);")
    pbx.append("\t\t\tpath = Screens;")
    pbx.append("\t\t\tsourceTree = \"<group>\";")
    pbx.append("\t\t};")

    pbx.append(f"\t\t{resources_group_id} /* Resources */ = {{")
    pbx.append("\t\t\tisa = PBXGroup;")
    pbx.append("\t\t\tchildren = (")
    pbx.append(f"\t\t\t\t{filerefs['src/Resources/assessment_catalog.json']} /* assessment_catalog.json */,")
    pbx.append("\t\t\t);")
    pbx.append("\t\t\tpath = Resources;")
    pbx.append("\t\t\tsourceTree = \"<group>\";")
    pbx.append("\t\t};")

    pbx.append(f"\t\t{tests_group_id} /* Tests */ = {{")
    pbx.append("\t\t\tisa = PBXGroup;")
    pbx.append("\t\t\tchildren = (")
    for f in ["CatalogTests.swift", "ColorTokenTests.swift", "EvaluationEngineTests.swift", "UIComponentTests.swift", "AssessmentViewModelTests.swift", "HapticFeedbackServiceTests.swift"]:
        pbx.append(f"\t\t\t\t{filerefs['src/Tests/' + f]} /* {f} */,")
    pbx.append("\t\t\t);")
    pbx.append("\t\t\tpath = Tests;")
    pbx.append("\t\t\tsourceTree = \"<group>\";")
    pbx.append("\t\t};")

    pbx.append("/* End PBXGroup section */")

    # PBXNativeTarget section
    pbx.append("\n/* Begin PBXNativeTarget section */")
    pbx.append(f"\t\t{app_target_id} /* AssessYourself */ = {{")
    pbx.append("\t\t\tisa = PBXNativeTarget;")
    pbx.append(f"\t\t\tbuildConfigurationList = {app_cfg_list_id} /* Build configuration list for PBXNativeTarget \"AssessYourself\" */;")
    pbx.append("\t\t\tbuildPhases = (")
    pbx.append(f"\t\t\t\t{app_sources_phase_id} /* Sources */,")
    pbx.append(f"\t\t\t\t{app_frameworks_phase_id} /* Frameworks */,")
    pbx.append(f"\t\t\t\t{app_resources_phase_id} /* Resources */,")
    pbx.append("\t\t\t);")
    pbx.append("\t\t\tbuildRules = (")
    pbx.append("\t\t\t);")
    pbx.append("\t\t\tdependencies = (")
    pbx.append("\t\t\t);")
    pbx.append("\t\t\tname = AssessYourself;")
    pbx.append("\t\t\tproductName = AssessYourself;")
    pbx.append(f"\t\t\tproductReference = {app_product_id} /* AssessYourself.app */;")
    pbx.append("\t\t\tproductType = \"com.apple.product-type.application\";")
    pbx.append("\t\t};")

    pbx.append(f"\t\t{test_target_id} /* AssessYourselfTests */ = {{")
    pbx.append("\t\t\tisa = PBXNativeTarget;")
    pbx.append(f"\t\t\tbuildConfigurationList = {test_cfg_list_id} /* Build configuration list for PBXNativeTarget \"AssessYourselfTests\" */;")
    pbx.append("\t\t\tbuildPhases = (")
    pbx.append(f"\t\t\t\t{test_sources_phase_id} /* Sources */,")
    pbx.append(f"\t\t\t\t{test_frameworks_phase_id} /* Frameworks */,")
    pbx.append(f"\t\t\t\t{test_resources_phase_id} /* Resources */,")
    pbx.append("\t\t\t);")
    pbx.append("\t\t\tbuildRules = (")
    pbx.append("\t\t\t);")
    pbx.append("\t\t\tdependencies = (")
    pbx.append(f"\t\t\t\t{target_dep_id} /* PBXTargetDependency */,")
    pbx.append("\t\t\t);")
    pbx.append("\t\t\tname = AssessYourselfTests;")
    pbx.append("\t\t\tproductName = AssessYourselfTests;")
    pbx.append(f"\t\t\tproductReference = {test_product_id} /* AssessYourselfTests.xctest */;")
    pbx.append("\t\t\tproductType = \"com.apple.product-type.bundle.unit-test\";")
    pbx.append("\t\t};")

    pbx.append(f"\t\t{ui_test_target_id} /* AssessYourselfUITests */ = {{")
    pbx.append("\t\t\tisa = PBXNativeTarget;")
    pbx.append(f"\t\t\tbuildConfigurationList = {ui_test_cfg_list_id} /* Build configuration list for PBXNativeTarget \"AssessYourselfUITests\" */;")
    pbx.append("\t\t\tbuildPhases = (")
    pbx.append(f"\t\t\t\t{ui_test_sources_phase_id} /* Sources */,")
    pbx.append(f"\t\t\t\t{ui_test_frameworks_phase_id} /* Frameworks */,")
    pbx.append(f"\t\t\t\t{ui_test_resources_phase_id} /* Resources */,")
    pbx.append("\t\t\t);")
    pbx.append("\t\t\tbuildRules = (")
    pbx.append("\t\t\t);")
    pbx.append("\t\t\tdependencies = (")
    pbx.append(f"\t\t\t\t{ui_target_dep_id} /* PBXTargetDependency */,")
    pbx.append("\t\t\t);")
    pbx.append("\t\t\tname = AssessYourselfUITests;")
    pbx.append("\t\t\tproductName = AssessYourselfUITests;")
    pbx.append(f"\t\t\tproductReference = {ui_test_product_id} /* AssessYourselfUITests.xctest */;")
    pbx.append("\t\t\tproductType = \"com.apple.product-type.bundle.ui-testing\";")
    pbx.append("\t\t};")
    pbx.append("/* End PBXNativeTarget section */")

    # PBXProject section
    pbx.append("\n/* Begin PBXProject section */")
    pbx.append(f"\t\t{proj_id} /* Project object */ = {{")
    pbx.append("\t\t\tisa = PBXProject;")
    pbx.append("\t\t\tattributes = {")
    pbx.append("\t\t\t\tBuildIndependentTargetsInParallel = 1;")
    pbx.append("\t\t\t\tLastSwiftUpdateCheck = 1500;")
    pbx.append("\t\t\t\tLastUpgradeCheck = 1500;")
    pbx.append("\t\t\t\tTargetAttributes = {")
    pbx.append(f"\t\t\t\t\t{app_target_id} = {{")
    pbx.append("\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;")
    pbx.append("\t\t\t\t\t};")
    pbx.append(f"\t\t\t\t\t{test_target_id} = {{")
    pbx.append("\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;")
    pbx.append(f"\t\t\t\t\t\tTestTargetID = {app_target_id};")
    pbx.append("\t\t\t\t\t};")
    pbx.append(f"\t\t\t\t\t{ui_test_target_id} = {{")
    pbx.append("\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;")
    pbx.append(f"\t\t\t\t\t\tTestTargetID = {app_target_id};")
    pbx.append("\t\t\t\t\t};")
    pbx.append("\t\t\t\t};")
    pbx.append("\t\t\t};")
    pbx.append(f"\t\t\tbuildConfigurationList = {proj_cfg_list_id} /* Build configuration list for PBXProject \"AssessYourself\" */;")
    pbx.append("\t\t\tcompatibilityVersion = \"Xcode 14.0\";")
    pbx.append("\t\t\tdevelopmentRegion = en;")
    pbx.append("\t\t\thasScannedForEncodings = 0;")
    pbx.append("\t\t\tknownRegions = (")
    pbx.append("\t\t\t\ten,")
    pbx.append("\t\t\t\tBase,")
    pbx.append("\t\t\t);")
    pbx.append(f"\t\t\tmainGroup = {main_group_id};")
    pbx.append(f"\t\t\tproductRefGroup = {products_group_id} /* Products */;")
    pbx.append("\t\t\tprojectDirPath = \"\";")
    pbx.append("\t\t\tprojectRoot = \"\";")
    pbx.append("\t\t\ttargets = (")
    pbx.append(f"\t\t\t\t{app_target_id} /* AssessYourself */,")
    pbx.append(f"\t\t\t\t{test_target_id} /* AssessYourselfTests */,")
    pbx.append(f"\t\t\t\t{ui_test_target_id} /* AssessYourselfUITests */,")
    pbx.append("\t\t\t);")
    pbx.append("\t\t};")
    pbx.append("/* End PBXProject section */")

    # PBXResourcesBuildPhase
    pbx.append("\n/* Begin PBXResourcesBuildPhase section */")
    pbx.append(f"\t\t{app_resources_phase_id} /* Resources */ = {{")
    pbx.append("\t\t\tisa = PBXResourcesBuildPhase;")
    pbx.append("\t\t\tbuildActionMask = 2147483647;")
    pbx.append("\t\t\tfiles = (")
    for path in app_resources:
        bf = buildfiles[path]["app"]
        pbx.append(f"\t\t\t\t{bf} /* {path} in Resources */,")
    pbx.append("\t\t\t);")
    pbx.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    pbx.append("\t\t};")
    pbx.append(f"\t\t{test_resources_phase_id} /* Resources */ = {{")
    pbx.append("\t\t\tisa = PBXResourcesBuildPhase;")
    pbx.append("\t\t\tbuildActionMask = 2147483647;")
    pbx.append("\t\t\tfiles = (")
    pbx.append("\t\t\t);")
    pbx.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    pbx.append("\t\t};")
    pbx.append(f"\t\t{ui_test_resources_phase_id} /* Resources */ = {{")
    pbx.append("\t\t\tisa = PBXResourcesBuildPhase;")
    pbx.append("\t\t\tbuildActionMask = 2147483647;")
    pbx.append("\t\t\tfiles = (")
    pbx.append("\t\t\t);")
    pbx.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    pbx.append("\t\t};")
    pbx.append("/* End PBXResourcesBuildPhase section */")

    # PBXSourcesBuildPhase
    pbx.append("\n/* Begin PBXSourcesBuildPhase section */")
    pbx.append(f"\t\t{app_sources_phase_id} /* Sources */ = {{")
    pbx.append("\t\t\tisa = PBXSourcesBuildPhase;")
    pbx.append("\t\t\tbuildActionMask = 2147483647;")
    pbx.append("\t\t\tfiles = (")
    for path in app_sources:
        bf = buildfiles[path]["app"]
        pbx.append(f"\t\t\t\t{bf} /* {path} in Sources */,")
    pbx.append("\t\t\t);")
    pbx.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    pbx.append("\t\t};")

    pbx.append(f"\t\t{test_sources_phase_id} /* Sources */ = {{")
    pbx.append("\t\t\tisa = PBXSourcesBuildPhase;")
    pbx.append("\t\t\tbuildActionMask = 2147483647;")
    pbx.append("\t\t\tfiles = (")
    for path in test_sources:
        bf = buildfiles[path]["test"]
        pbx.append(f"\t\t\t\t{bf} /* {path} in Sources */,")
    pbx.append("\t\t\t);")
    pbx.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    pbx.append("\t\t};")

    pbx.append(f"\t\t{ui_test_sources_phase_id} /* Sources */ = {{")
    pbx.append("\t\t\tisa = PBXSourcesBuildPhase;")
    pbx.append("\t\t\tbuildActionMask = 2147483647;")
    pbx.append("\t\t\tfiles = (")
    for path in ui_test_sources:
        bf = buildfiles[path]["uitest"]
        pbx.append(f"\t\t\t\t{bf} /* {path} in Sources */,")
    pbx.append("\t\t\t);")
    pbx.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    pbx.append("\t\t};")
    pbx.append("/* End PBXSourcesBuildPhase section */")

    # PBXTargetDependency
    pbx.append("\n/* Begin PBXTargetDependency section */")
    pbx.append(f"\t\t{target_dep_id} /* PBXTargetDependency */ = {{")
    pbx.append("\t\t\tisa = PBXTargetDependency;")
    pbx.append(f"\t\t\ttarget = {app_target_id} /* AssessYourself */;")
    pbx.append(f"\t\t\ttargetProxy = {container_item_id} /* PBXContainerItemProxy */;")
    pbx.append("\t\t};")
    pbx.append(f"\t\t{ui_target_dep_id} /* PBXTargetDependency */ = {{")
    pbx.append("\t\t\tisa = PBXTargetDependency;")
    pbx.append(f"\t\t\ttarget = {app_target_id} /* AssessYourself */;")
    pbx.append(f"\t\t\ttargetProxy = {ui_container_item_id} /* PBXContainerItemProxy */;")
    pbx.append("\t\t};")
    pbx.append("/* End PBXTargetDependency section */")

    # Build Configuration Settings
    build_version = "20261104.090000"
    market_version = "0.5.1"

    # XCBuildConfiguration
    pbx.append("\n/* Begin XCBuildConfiguration section */")
    # Proj Debug
    pbx.append(f"\t\t{proj_debug_cfg_id} /* Debug */ = {{")
    pbx.append("\t\t\tisa = XCBuildConfiguration;")
    pbx.append("\t\t\tbuildSettings = {")
    pbx.append("\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;")
    pbx.append("\t\t\t\tCLANG_ANALYZER_NONNULL = YES;")
    pbx.append("\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = \"gnu++20\";")
    pbx.append("\t\t\t\tCLANG_ENABLE_MODULES = YES;")
    pbx.append("\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;")
    pbx.append("\t\t\t\tENABLE_TESTABILITY = YES;")
    pbx.append("\t\t\t\tGCC_DYNAMIC_NO_PIC = NO;")
    pbx.append("\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;")
    pbx.append("\t\t\t\tGCC_PREPROCESSOR_DEFINITIONS = (")
    pbx.append("\t\t\t\t\t\"DEBUG=1\",")
    pbx.append("\t\t\t\t\t\"$(inherited)\",")
    pbx.append("\t\t\t\t);")
    pbx.append("\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;")
    pbx.append("\t\t\t\tMTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;")
    pbx.append("\t\t\t\tMTL_FAST_MATH = YES;")
    pbx.append("\t\t\t\tONLY_ACTIVE_ARCH = YES;")
    pbx.append("\t\t\t\tSDKROOT = iphoneos;")
    pbx.append("\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;")
    pbx.append("\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = \"-Onone\";")
    pbx.append("\t\t\t};")
    pbx.append("\t\t\tname = Debug;")
    pbx.append("\t\t};")

    # Proj Release
    pbx.append(f"\t\t{proj_release_cfg_id} /* Release */ = {{")
    pbx.append("\t\t\tisa = XCBuildConfiguration;")
    pbx.append("\t\t\tbuildSettings = {")
    pbx.append("\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;")
    pbx.append("\t\t\t\tCLANG_ANALYZER_NONNULL = YES;")
    pbx.append("\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = \"gnu++20\";")
    pbx.append("\t\t\t\tCLANG_ENABLE_MODULES = YES;")
    pbx.append("\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;")
    pbx.append("\t\t\t\tENABLE_NS_ASSERTIONS = NO;")
    pbx.append("\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;")
    pbx.append("\t\t\t\tMTL_ENABLE_DEBUG_INFO = NO;")
    pbx.append("\t\t\t\tMTL_FAST_MATH = YES;")
    pbx.append("\t\t\t\tSDKROOT = iphoneos;")
    pbx.append("\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;")
    pbx.append("\t\t\t\tVALIDATE_PRODUCT = YES;")
    pbx.append("\t\t\t};")
    pbx.append("\t\t\tname = Release;")
    pbx.append("\t\t};")

    # App Debug
    pbx.append(f"\t\t{app_debug_cfg_id} /* Debug */ = {{")
    pbx.append("\t\t\tisa = XCBuildConfiguration;")
    pbx.append("\t\t\tbuildSettings = {")
    pbx.append("\t\t\t\tCODE_SIGN_STYLE = Automatic;")
    pbx.append(f"\t\t\t\tCURRENT_PROJECT_VERSION = {build_version};")
    pbx.append("\t\t\t\tENABLE_PREVIEWS = YES;")
    pbx.append("\t\t\t\tGENERATE_INFOPLIST_FILE = YES;")
    pbx.append("\t\t\t\tINFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;")
    pbx.append("\t\t\t\tINFOPLIST_KEY_UILaunchScreen_Generation = YES;")
    pbx.append("\t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations = \"UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight\";")
    pbx.append("\t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = \"UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight\";")
    pbx.append("\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (")
    pbx.append("\t\t\t\t\t\"$(inherited)\",")
    pbx.append("\t\t\t\t\t\"@executable_path/Frameworks\",")
    pbx.append("\t\t\t\t);")
    pbx.append(f"\t\t\t\tMARKETING_VERSION = {market_version};")
    pbx.append("\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.scherenhaenden.AssessYourself;")
    pbx.append("\t\t\t\tPRODUCT_NAME = \"$(TARGET_NAME)\";")
    pbx.append("\t\t\t\tPRODUCT_MODULE_NAME = AssessYourselfCore;")
    pbx.append("\t\t\t\tSWIFT_VERSION = 5.0;")
    pbx.append("\t\t\t\tTARGETED_DEVICE_FAMILY = \"1,2\";")
    pbx.append("\t\t\t};")
    pbx.append("\t\t\tname = Debug;")
    pbx.append("\t\t};")

    # App Release
    pbx.append(f"\t\t{app_release_cfg_id} /* Release */ = {{")
    pbx.append("\t\t\tisa = XCBuildConfiguration;")
    pbx.append("\t\t\tbuildSettings = {")
    pbx.append("\t\t\t\tCODE_SIGN_STYLE = Automatic;")
    pbx.append(f"\t\t\t\tCURRENT_PROJECT_VERSION = {build_version};")
    pbx.append("\t\t\t\tENABLE_PREVIEWS = YES;")
    pbx.append("\t\t\t\tGENERATE_INFOPLIST_FILE = YES;")
    pbx.append("\t\t\t\tINFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;")
    pbx.append("\t\t\t\tINFOPLIST_KEY_UILaunchScreen_Generation = YES;")
    pbx.append("\t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations = \"UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight\";")
    pbx.append("\t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = \"UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight\";")
    pbx.append("\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (")
    pbx.append("\t\t\t\t\t\"$(inherited)\",")
    pbx.append("\t\t\t\t\t\"@executable_path/Frameworks\",")
    pbx.append("\t\t\t\t);")
    pbx.append(f"\t\t\t\tMARKETING_VERSION = {market_version};")
    pbx.append("\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.scherenhaenden.AssessYourself;")
    pbx.append("\t\t\t\tPRODUCT_NAME = \"$(TARGET_NAME)\";")
    pbx.append("\t\t\t\tPRODUCT_MODULE_NAME = AssessYourselfCore;")
    pbx.append("\t\t\t\tSWIFT_VERSION = 5.0;")
    pbx.append("\t\t\t\tTARGETED_DEVICE_FAMILY = \"1,2\";")
    pbx.append("\t\t\t};")
    pbx.append("\t\t\tname = Release;")
    pbx.append("\t\t};")

    # Test Debug
    pbx.append(f"\t\t{test_debug_cfg_id} /* Debug */ = {{")
    pbx.append("\t\t\tisa = XCBuildConfiguration;")
    pbx.append("\t\t\tbuildSettings = {")
    pbx.append("\t\t\t\tCODE_SIGN_STYLE = Automatic;")
    pbx.append(f"\t\t\t\tCURRENT_PROJECT_VERSION = {build_version};")
    pbx.append("\t\t\t\tGENERATE_INFOPLIST_FILE = YES;")
    pbx.append("\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;")
    pbx.append(f"\t\t\t\tMARKETING_VERSION = {market_version};")
    pbx.append("\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.scherenhaenden.AssessYourselfTests;")
    pbx.append("\t\t\t\tPRODUCT_NAME = \"$(TARGET_NAME)\";")
    pbx.append("\t\t\t\tSWIFT_VERSION = 5.0;")
    pbx.append("\t\t\t\tTARGETED_DEVICE_FAMILY = \"1,2\";")
    pbx.append("\t\t\t\tTEST_HOST = \"$(BUILT_PRODUCTS_DIR)/AssessYourself.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/AssessYourself\";")
    pbx.append("\t\t\t\tBUNDLE_LOADER = \"$(TEST_HOST)\";")
    pbx.append("\t\t\t};")
    pbx.append("\t\t\tname = Debug;")
    pbx.append("\t\t};")

    # Test Release
    pbx.append(f"\t\t{test_release_cfg_id} /* Release */ = {{")
    pbx.append("\t\t\tisa = XCBuildConfiguration;")
    pbx.append("\t\t\tbuildSettings = {")
    pbx.append("\t\t\t\tCODE_SIGN_STYLE = Automatic;")
    pbx.append(f"\t\t\t\tCURRENT_PROJECT_VERSION = {build_version};")
    pbx.append("\t\t\t\tGENERATE_INFOPLIST_FILE = YES;")
    pbx.append("\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;")
    pbx.append(f"\t\t\t\tMARKETING_VERSION = {market_version};")
    pbx.append("\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.scherenhaenden.AssessYourselfTests;")
    pbx.append("\t\t\t\tPRODUCT_NAME = \"$(TARGET_NAME)\";")
    pbx.append("\t\t\t\tSWIFT_VERSION = 5.0;")
    pbx.append("\t\t\t\tTARGETED_DEVICE_FAMILY = \"1,2\";")
    pbx.append("\t\t\t\tTEST_HOST = \"$(BUILT_PRODUCTS_DIR)/AssessYourself.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/AssessYourself\";")
    pbx.append("\t\t\t\tBUNDLE_LOADER = \"$(TEST_HOST)\";")
    pbx.append("\t\t\t};")
    pbx.append("\t\t\tname = Release;")
    pbx.append("\t\t};")

    # UITest Debug
    pbx.append(f"\t\t{ui_test_debug_cfg_id} /* Debug */ = {{")
    pbx.append("\t\t\tisa = XCBuildConfiguration;")
    pbx.append("\t\t\tbuildSettings = {")
    pbx.append("\t\t\t\tCODE_SIGN_STYLE = Automatic;")
    pbx.append(f"\t\t\t\tCURRENT_PROJECT_VERSION = {build_version};")
    pbx.append("\t\t\t\tGENERATE_INFOPLIST_FILE = YES;")
    pbx.append("\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;")
    pbx.append(f"\t\t\t\tMARKETING_VERSION = {market_version};")
    pbx.append("\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.scherenhaenden.AssessYourselfUITests;")
    pbx.append("\t\t\t\tPRODUCT_NAME = \"$(TARGET_NAME)\";")
    pbx.append("\t\t\t\tSWIFT_VERSION = 5.0;")
    pbx.append("\t\t\t\tTARGETED_DEVICE_FAMILY = \"1,2\";")
    pbx.append("\t\t\t\tTEST_TARGET_NAME = AssessYourself;")
    pbx.append("\t\t\t};")
    pbx.append("\t\t\tname = Debug;")
    pbx.append("\t\t};")

    # UITest Release
    pbx.append(f"\t\t{ui_test_release_cfg_id} /* Release */ = {{")
    pbx.append("\t\t\tisa = XCBuildConfiguration;")
    pbx.append("\t\t\tbuildSettings = {")
    pbx.append("\t\t\t\tCODE_SIGN_STYLE = Automatic;")
    pbx.append(f"\t\t\t\tCURRENT_PROJECT_VERSION = {build_version};")
    pbx.append("\t\t\t\tGENERATE_INFOPLIST_FILE = YES;")
    pbx.append("\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;")
    pbx.append(f"\t\t\t\tMARKETING_VERSION = {market_version};")
    pbx.append("\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.scherenhaenden.AssessYourselfUITests;")
    pbx.append("\t\t\t\tPRODUCT_NAME = \"$(TARGET_NAME)\";")
    pbx.append("\t\t\t\tSWIFT_VERSION = 5.0;")
    pbx.append("\t\t\t\tTARGETED_DEVICE_FAMILY = \"1,2\";")
    pbx.append("\t\t\t\tTEST_TARGET_NAME = AssessYourself;")
    pbx.append("\t\t\t};")
    pbx.append("\t\t\tname = Release;")
    pbx.append("\t\t};")
    pbx.append("/* End XCBuildConfiguration section */")

    # XCConfigurationList
    pbx.append("\n/* Begin XCConfigurationList section */")
    pbx.append(f"\t\t{proj_cfg_list_id} /* Build configuration list for PBXProject \"AssessYourself\" */ = {{")
    pbx.append("\t\t\tisa = XCConfigurationList;")
    pbx.append("\t\t\tbuildConfigurations = (")
    pbx.append(f"\t\t\t\t{proj_debug_cfg_id} /* Debug */,")
    pbx.append(f"\t\t\t\t{proj_release_cfg_id} /* Release */,")
    pbx.append("\t\t\t);")
    pbx.append("\t\t\tdefaultConfigurationIsVisible = 0;")
    pbx.append("\t\t\tdefaultConfigurationName = Debug;")
    pbx.append("\t\t};")

    pbx.append(f"\t\t{app_cfg_list_id} /* Build configuration list for PBXNativeTarget \"AssessYourself\" */ = {{")
    pbx.append("\t\t\tisa = XCConfigurationList;")
    pbx.append("\t\t\tbuildConfigurations = (")
    pbx.append(f"\t\t\t\t{app_debug_cfg_id} /* Debug */,")
    pbx.append(f"\t\t\t\t{app_release_cfg_id} /* Release */,")
    pbx.append("\t\t\t);")
    pbx.append("\t\t\tdefaultConfigurationIsVisible = 0;")
    pbx.append("\t\t\tdefaultConfigurationName = Debug;")
    pbx.append("\t\t};")

    pbx.append(f"\t\t{test_cfg_list_id} /* Build configuration list for PBXNativeTarget \"AssessYourselfTests\" */ = {{")
    pbx.append("\t\t\tisa = XCConfigurationList;")
    pbx.append("\t\t\tbuildConfigurations = (")
    pbx.append(f"\t\t\t\t{test_debug_cfg_id} /* Debug */,")
    pbx.append(f"\t\t\t\t{test_release_cfg_id} /* Release */,")
    pbx.append("\t\t\t);")
    pbx.append("\t\t\tdefaultConfigurationIsVisible = 0;")
    pbx.append("\t\t\tdefaultConfigurationName = Debug;")
    pbx.append("\t\t};")

    pbx.append(f"\t\t{ui_test_cfg_list_id} /* Build configuration list for PBXNativeTarget \"AssessYourselfUITests\" */ = {{")
    pbx.append("\t\t\tisa = XCConfigurationList;")
    pbx.append("\t\t\tbuildConfigurations = (")
    pbx.append(f"\t\t\t\t{ui_test_debug_cfg_id} /* Debug */,")
    pbx.append(f"\t\t\t\t{ui_test_release_cfg_id} /* Release */,")
    pbx.append("\t\t\t);")
    pbx.append("\t\t\tdefaultConfigurationIsVisible = 0;")
    pbx.append("\t\t\tdefaultConfigurationName = Debug;")
    pbx.append("\t\t};")
    pbx.append("/* End XCConfigurationList section */")

    pbx.append("\t};")
    pbx.append(f"\trootObject = {proj_id} /* Project object */;")
    pbx.append("}")

    pbx_path = os.path.join(proj_dir, "project.pbxproj")
    with open(pbx_path, "w", encoding="utf-8") as f:
        f.write("\n".join(pbx))

    print(f"Generated {pbx_path}")

    # Generate AssessYourself.xcscheme with both Unit and UI tests
    scheme = f"""<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1500"
   version = "1.3">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{app_target_id}"
               BuildableName = "AssessYourself.app"
               BlueprintName = "AssessYourself"
               ReferencedContainer = "container:AssessYourself.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "NO"
            buildForProfiling = "NO"
            buildForArchiving = "NO"
            buildForAnalyzing = "NO">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{test_target_id}"
               BuildableName = "AssessYourselfTests.xctest"
               BlueprintName = "AssessYourselfTests"
               ReferencedContainer = "container:AssessYourself.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "NO"
            buildForProfiling = "NO"
            buildForArchiving = "NO"
            buildForAnalyzing = "NO">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{ui_test_target_id}"
               BuildableName = "AssessYourselfUITests.xctest"
               BlueprintName = "AssessYourselfUITests"
               ReferencedContainer = "container:AssessYourself.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
      <MacroExpansion>
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{app_target_id}"
            BuildableName = "AssessYourself.app"
            BlueprintName = "AssessYourself"
            ReferencedContainer = "container:AssessYourself.xcodeproj">
         </BuildableReference>
      </MacroExpansion>
      <Testables>
         <TestableReference
            skipped = "NO">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{test_target_id}"
               BuildableName = "AssessYourselfTests.xctest"
               BlueprintName = "AssessYourselfTests"
               ReferencedContainer = "container:AssessYourself.xcodeproj">
            </BuildableReference>
         </TestableReference>
         <TestableReference
            skipped = "NO">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{ui_test_target_id}"
               BuildableName = "AssessYourselfUITests.xctest"
               BlueprintName = "AssessYourselfUITests"
               ReferencedContainer = "container:AssessYourself.xcodeproj">
            </BuildableReference>
         </TestableReference>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{app_target_id}"
            BuildableName = "AssessYourself.app"
            BlueprintName = "AssessYourself"
            ReferencedContainer = "container:AssessYourself.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{app_target_id}"
            BuildableName = "AssessYourself.app"
            BlueprintName = "AssessYourself"
            ReferencedContainer = "container:AssessYourself.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
"""
    scheme_path = os.path.join(shared_schemes_dir, "AssessYourself.xcscheme")
    with open(scheme_path, "w", encoding="utf-8") as f:
        f.write(scheme)
    print(f"Generated {scheme_path}")

if __name__ == "__main__":
    main()
