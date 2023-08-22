import setuptools

setuptools.setup(
  name='test-hello',
  setup_path=__file__,
  packages=setuptools.find_packages(include=['hello*']),
  entry_points = {
    'console_scripts': [
      'test-hello = hello.main:main',
    ],
  }
)


