import setuptools

setuptools.setup(
  name='requires-setuptools',
  setup_path=__file__,
  packages=setuptools.find_packages(include=['setuptools_breaks_things*']),
  install_requires=[
    'setuptools',
  ],
)


