def setup(app):
    app.add_css_file('css/custom.css')


extensions = [
  'sphinx.ext.autosectionlabel',
  'sphinx.ext.todo',
  'sphinx_fontawesome',
  'sphinxcontrib.blockdiag',
  'sphinxcontrib.nwdiag'
]
source_suffix = '.rst'
master_doc = 'index'
project = u'OSISM Testbed'
copyright = u'2019-2021, Betacloud Solutions GmbH'
author = u'Betacloud Solutions GmbH'
version = u''
release = u''
language = 'en'
exclude_patterns = []
pygments_style = 'sphinx'
todo_include_todos = True
html_theme = 'sphinx_rtd_theme'
html_show_sphinx = False
html_show_sourcelink = False
html_show_copyright = True
htmlhelp_basename = 'documentation'
html_theme_options = {
    'display_version': False,
    'canonical_url': 'https://docs.osism.de/testbed/',
    'style_external_links': True,
    'logo_only': True,
    'prev_next_buttons_location': None
}
html_context = {
    'display_github': True,
    'github_user': 'osism',
    'github_repo': 'testbed',
    'github_version': 'master',
    'conf_py_path': '/docs/source/'
}
html_logo = 'images/logo.png'
html_static_path = [
    '_static'
]
latex_elements = {}
