# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2019 Blender Foundation.

# Find USD libraries in Houdini installation.
# Variables are matching those output by FindUSDPixar.cmake.

if(HOUDINI_ROOT AND EXISTS ${HOUDINI_ROOT})
  message(STATUS "Found Houdini: ${HOUDINI_ROOT}")

  set(USD_FOUND ON)

  # Houdini paths
  if(WIN32)
    set(_library_dir ${HOUDINI_ROOT}/custom/houdini/dsolib)
    set(_include_dir ${HOUDINI_ROOT}/toolkit/include)
    list(APPEND CMAKE_FIND_LIBRARY_PREFIXES lib "")
  elseif(APPLE)
    set(_library_dir ${HOUDINI_ROOT}/Frameworks/Houdini.framework/Libraries)
    set(_include_dir ${HOUDINI_ROOT}/Frameworks/Houdini.framework/Resources/toolkit/include)
  elseif(UNIX)
    set(_library_dir ${HOUDINI_ROOT}/dsolib)
    set(_include_dir ${HOUDINI_ROOT}/toolkit/include)
    set(_bin_dir ${HOUDINI_ROOT}/bin)
  endif()

  # Version and ABI
  file(STRINGS "${_include_dir}/HAPI/HAPI_Version.h" _houdini_version_major
    REGEX "^#define HAPI_VERSION_HOUDINI_MAJOR[ \t].*$")
  string(REGEX MATCHALL "[0-9]+" HOUDINI_VERSION_MAJOR ${_houdini_version_major})

  # USD
  set(USD_LIBRARIES hd hgi hgiGL gf arch garch plug tf trace vt work sdf cameraUtil hf pxOsd usd usdImaging usdGeom)

  foreach(lib ${USD_LIBRARIES})
    find_library(_pxr_library NAMES pxr_${lib} PATHS ${_library_dir} NO_DEFAULT_PATH)
    add_library(${lib} SHARED IMPORTED)
    set_property(TARGET ${lib} APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
    get_filename_component(_pxr_soname ${_pxr_library} NAME)
    set_target_properties(${lib} PROPERTIES
      IMPORTED_LOCATION_RELEASE "${_pxr_library}"
      IMPORTED_SONAME_RELEASE "${_pxr_soname}"
      IMPORTED_IMPLIB_RELEASE "${_pxr_library}"
    )
    unset(_pxr_library CACHE)
    unset(_pxr_soname)
  endforeach()

  # Python
  find_path(_python_include_dir NAMES "pyconfig.h" PATHS ${_include_dir}/* NO_DEFAULT_PATH)
  get_filename_component(_python_name ${_python_include_dir} NAME)
  string(REGEX REPLACE "python([0-9]+)\.([0-9]+)[m]?" "\\1" _python_major ${_python_name})
  string(REGEX REPLACE "python([0-9]+)\.([0-9]+)[m]?" "\\2" _python_minor ${_python_name})

  if(WIN32)
    set(_python_library_dir ${HOUDINI_ROOT}/python${_python_major}${_python_minor}/libs)
  elseif(APPLE)
    set(_python_library_dir ${HOUDINI_ROOT}/Frameworks/Python.framework/Versions/Current/lib)
  elseif(UNIX)
    set(_python_library_dir ${HOUDINI_ROOT}/python/lib)
  endif()

  find_library(_python_library
    NAMES
      python${_python_major}${_python_minor}
      python${_python_major}.${_python_minor}
      python${_python_major}.${_python_minor}m
    PATHS
      ${_python_library_dir}
    NO_DEFAULT_PATH)

  find_library(_boost_python_library
    NAMES
      hboost_python-mt
      hboost_python${_python_major}${_python_minor}
      hboost_python${_python_major}${_python_minor}-mt-x64
    PATHS
      ${_library_dir}
    NO_DEFAULT_PATH)

  set(USD_INCLUDE_DIR ${_include_dir})
  list(APPEND USD_INCLUDE_DIRS ${_python_include_dir})
  list(APPEND USD_LIBRARIES ${_python_library} ${_boost_python_library} pxr_python)

  set(PYTHON_VERSION ${_python_major}.${python_minor})
  set(PYTHON_LIBRARY ${_python_library})
  set(PYTHON_INCLUDE_DIR ${_python_include_dir})

  unset(_python_name)
  unset(_python_major)
  unset(_python_minor)
  unset(_python_library_dir)
  unset(_python_include_dir CACHE)
  unset(_python_library CACHE)
  unset(_boost_python_library CACHE)

  # ZLIB
  find_library(_zlib_library NAMES z PATHS ${_library_dir} NO_DEFAULT_PATH)
  set(ZLIB_INCLUDE_DIR ${_include_dir})
  set(ZLIB_LIBRARY ${_zlib_library})
  set(USD_OVERRIDE_ZLIB ON)
  unset(_zlib_library CACHE)

  # ZSTD
  find_library(_zstd_library NAMES zstd PATHS ${_library_dir} NO_DEFAULT_PATH)
  set(ZSTD_INCLUDE_DIR ${_include_dir})
  set(ZSTD_LIBRARY ${_zstd_library})
  set(USD_OVERRIDE_ZSTD ON)
  unset(_zstd_library CACHE)


  # Boost
  set(BOOST_DEFINITIONS "-DHBOOST_ALL_NO_LIB")

  # OpenSubdiv
  find_library(_opensubdiv_library_cpu NAMES osdCPU osdCPU_md PATHS ${_library_dir} NO_DEFAULT_PATH)
  find_library(_opensubdiv_library_gpu NAMES osdGPU osdGPU_md PATHS ${_library_dir} NO_DEFAULT_PATH)
  set(OPENSUBDIV_INCLUDE_DIRS ${_include_dir})
  set(OPENSUBDIV_LIBRARIES
    ${_opensubdiv_library_cpu}
    ${_opensubdiv_library_gpu}
  )
  set(USD_OVERRIDE_OPENSUBDIV ON)
  unset(_opensubdiv_library_cpu CACHE)
  unset(_opensubdiv_library_gpu CACHE)

  # OpenEXR
  find_library(_openexr_library NAMES OpenEXR_sidefx PATHS ${_library_dir} NO_DEFAULT_PATH)
  set(OPENEXR_INCLUDE_DIRS ${_include_dir})
  set(OPENEXR_LIBRARIES ${_openexr_library})
  set(OPENEXR_FOUND TRUE)
  set(USD_OVERRIDE_OPENEXR ON)
  unset(_openexr_library CACHE)

  # Alembic
  find_library(_alembic_library NAMES Alembic_sidefx PATHS ${_library_dir} NO_DEFAULT_PATH)
  set(ALEMBIC_INCLUDE_DIRS ${_include_dir} ${_include_dir}/Imath)
  set(ALEMBIC_LIBRARIES ${_alembic_library})
  set(ALEMBIC_FOUND TRUE)
  set(USD_OVERRIDE_ALEMBIC ON)
  unset(_alembic_library CACHE)

  # OpenVDB
  find_library(_openvdb_library NAMES openvdb_sesi PATHS ${_library_dir} NO_DEFAULT_PATH)
  set(OPENVDB_INCLUDE_DIRS ${_include_dir})
  set(OPENVDB_LIBRARIES ${_openvdb_library})
  set(USD_OVERRIDE_OPENVDB ON)
  unset(_openvdb_library CACHE)

  # MaterialX
  find_library(_materialx_library NAMES MaterialXCore MaterialXFormat MaterialRender MaterialXGenGlsl MaterialXGenMsl PATHS ${_library_dir} NO_DEFAULT_PATH)
  set(MATERIALX_INCLUDE_DIRS ${_include_dir})
  set(MATERIALX_LIBRARIES ${_library_dir})
  set(MATERIALX_FOUND ON)
  set(USD_OVERRIDE_MATERIALX ON)
  unset(_materialx_library CACHE)

  # NanoVDB
  set(NANOVDB_INCLUDE_DIR ${_include_dir})
  set(NANOVDB_FOUND TRUE)

  # TBB
  find_library(_tbb_library NAMES tbb PATHS ${_library_dir} NO_DEFAULT_PATH)
  set(TBB_INCLUDE_DIRS ${_include_dir})
  set(TBB_LIBRARIES ${_tbb_library})
  set(USD_OVERRIDE_TBB ON)
  unset(_tbb_library CACHE)

  # OpenColorIO
  find_library(_opencolorio_library NAMES OpenColorIO_sidefx PATHS ${_library_dir} NO_DEFAULT_PATH)
  set(OPENCOLORIO_INCLUDE_DIRS ${_include_dir})
  set(OPENCOLORIO_LIBRARIES ${_opencolorio_library})
  set(OpenColorIO_FOUND TRUE)
  set(USD_OVERRIDE_OPENCOLORIO ON)
  unset(_opencolorio_library CACHE)

  # OpenImageIO
  find_library(_openimageio_library NAMES OpenImageIO_sidefx PATHS ${_library_dir} NO_DEFAULT_PATH)
  find_library(_openimageio_util_library NAMES OpenImageIO_Util_sidefx PATHS ${_library_dir} NO_DEFAULT_PATH)
  set(OPENIMAGEIO_INCLUDE_DIRS ${_include_dir})
  set(OPENIMAGEIO_LIBRARIES ${_openimageio_library} ${_openimageio_util_library})
  set(OPENIMAGEIO_TOOL "${_bin_dir}/hoiiotool")
  set(OPENIMAGEIO_FOUND TRUE)
  set(USD_OVERRIDE_OPENIMAGEIO ON)

  # FMT
  set(FMT_FOUND TRUE)

  unset(_openimageio_library CACHE)
  unset(_openimageio_util_library CACHE)

  # OpenImageDenoise
  find_library(_openimagedenoise_library NAMES OpenImageDenoise PATHS ${_library_dir} NO_DEFAULT_PATH)
  set(OPENIMAGEDENOISE_INCLUDE_DIRS ${_include_dir})
  set(OPENIMAGEDENOISE_LIBRARIES ${_openimagedenoise_library})
  set(OPENIMAGEDENOISE_FOUND TRUE)
  set(USD_OVERRIDE_OPENIMAGEDENOISE ON)
  unset(_openimagedenoise_library CACHE)

  # PugiXML
  set(PUGIXML_ROOT_DIR ${CMAKE_SOURCE_DIR}/lib/houdini)

  # OpenJPEG
  set(OPENJPEG_ROOT_DIR ${CMAKE_SOURCE_DIR}/lib/houdini)

  # Epoxy
  set(EPOXY_ROOT_DIR ${CMAKE_SOURCE_DIR}/lib/houdini)



  # JPEG
  find_library(_jpeg_library NAMES jpeg PATHS ${_library_dir} NO_DEFAULT_PATH)
  set(JPEG_INCLUDE_DIRS ${_include_dir})
  set(JPEG_LIBRARIES ${_jpeg_library})
  set(JPEG_FOUND TRUE)
  set(USD_OVERRIDE_JPEG ON)
  unset(_jpeg_library CACHE)

  # TIFF
  find_library(_tiff_library NAMES tiff PATHS ${_library_dir} NO_DEFAULT_PATH)
  set(TIFF_INCLUDE_DIRS ${_include_dir})
  set(TIFF_LIBRARIES ${_tiff_library})
  set(TIFF_FOUND TRUE)
  set(USD_OVERRIDE_TIFF ON)
  unset(_tiff_library CACHE)

  # PNG
  find_library(_png_library NAMES png PATHS ${_library_dir} NO_DEFAULT_PATH)
  set(PNG_INCLUDE_DIRS ${_include_dir})
  set(PNG_LIBRARIES ${_png_library})
  set(PNG_FOUND TRUE)
  set(USD_OVERRIDE_PNG ON)
  unset(_png_library CACHE)

  # OSL
  find_library(_osl_library NAMES HOSL PATHS ${_library_dir} NO_DEFAULT_PATH)
  set(OSL_INCLUDE_DIRS ${_include_dir})
  set(OSL_LIBRARIES ${_osl_library})
  set(OSL_FOUND TRUE)
  set(USD_OVERRIDE_OSL ON)
  set(WITH_CYCLES_OSL OFF)
  unset(_osl_library CACHE)

  # Embree
  find_library(_embree_library NAMES embree_sidefx PATHS ${_library_dir} NO_DEFAULT_PATH)
  set(EMBREE_INCLUDE_DIRS ${_include_dir})
  set(EMBREE_LIBRARIES ${_embree_library})
  set(EMBREE_FOUND TRUE)
  set(WITH_CYCLES_EMBREE TRUE)
  set(USD_OVERRIDE_EMBREE ON)
  unset(_embree_library CACHE)

  # Cleanup
  unset(_library_dir)
  unset(_include_dir)

  add_definitions(-DHOUDINI)
  add_definitions(-DWITH_EMBREE)
  add_definitions(-DEMBREE_MAJOR_VERSION=3)
else()
  message(STATUS "Did not find Houdini at ${HOUDINI_ROOT}")
endif()
