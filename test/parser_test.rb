# frozen_string_literal: true
require_relative 'test_helper'

context "Parser" do
  test "is_section_title?" do
    assert Asciidoctor::Parser.is_section_title?('AsciiDoc Home Page', '==================')
    assert Asciidoctor::Parser.is_section_title?('=== AsciiDoc Home Page')
  end

  test 'sanitize attribute name' do
    assert_equal 'foobar', Asciidoctor::Parser.sanitize_attribute_name("Foo Bar")
    assert_equal 'foo', Asciidoctor::Parser.sanitize_attribute_name("foo")
    assert_equal 'foo3-bar', Asciidoctor::Parser.sanitize_attribute_name("Foo 3^ # - Bar[")
  end

  test 'store attribute with value' do
    attr_name, attr_value = Asciidoctor::Parser.store_attribute 'foo', 'bar'
    assert_equal 'foo', attr_name
    assert_equal 'bar', attr_value
  end

  test 'store attribute with negated value' do
    { 'foo!' => nil, '!foo' => nil, 'foo' => nil }.each do |name, value|
      attr_name, attr_value = Asciidoctor::Parser.store_attribute name, value
      assert_equal name.sub('!', ''), attr_name
      assert_nil attr_value
    end
  end

  test 'store accessible attribute on document with value' do
    doc = empty_document
    doc.set_attribute 'foo', 'baz'
    attrs = {}
    attr_name, attr_value = Asciidoctor::Parser.store_attribute 'foo', 'bar', doc, attrs
    assert_equal 'foo', attr_name
    assert_equal 'bar', attr_value
    assert_equal 'bar', (doc.attr 'foo')
    assert attrs.key?(:attribute_entries)
    assert_equal 1, attrs[:attribute_entries].size
    assert_equal 'foo', attrs[:attribute_entries][0].name
    assert_equal 'bar', attrs[:attribute_entries][0].value
  end

  test 'store accessible attribute on document with value that contains attribute reference' do
    doc = empty_document
    doc.set_attribute 'foo', 'baz'
    doc.set_attribute 'release', 'ultramega'
    attrs = {}
    attr_name, attr_value = Asciidoctor::Parser.store_attribute 'foo', '{release}', doc, attrs
    assert_equal 'foo', attr_name
    assert_equal 'ultramega', attr_value
    assert_equal 'ultramega', (doc.attr 'foo')
    assert attrs.key?(:attribute_entries)
    assert_equal 1, attrs[:attribute_entries].size
    assert_equal 'foo', attrs[:attribute_entries][0].name
    assert_equal 'ultramega', attrs[:attribute_entries][0].value
  end

  test 'store inaccessible attribute on document with value' do
    doc = empty_document attributes: { 'foo' => 'baz' }
    attrs = {}
    attr_name, attr_value = Asciidoctor::Parser.store_attribute 'foo', 'bar', doc, attrs
    assert_equal 'foo', attr_name
    assert_equal 'bar', attr_value
    assert_equal 'baz', (doc.attr 'foo')
    refute attrs.key?(:attribute_entries)
  end

  test 'store accessible attribute on document with negated value' do
    { 'foo!' => nil, '!foo' => nil, 'foo' => nil }.each do |name, value|
      doc = empty_document
      doc.set_attribute 'foo', 'baz'
      attrs = {}
      attr_name, attr_value = Asciidoctor::Parser.store_attribute name, value, doc, attrs
      assert_equal name.sub('!', ''), attr_name
      assert_nil attr_value
      assert attrs.key?(:attribute_entries)
      assert_equal 1, attrs[:attribute_entries].size
      assert_equal 'foo', attrs[:attribute_entries][0].name
      assert_nil attrs[:attribute_entries][0].value
    end
  end

  test 'store inaccessible attribute on document with negated value' do
    { 'foo!' => nil, '!foo' => nil, 'foo' => nil }.each do |name, value|
      doc = empty_document attributes: { 'foo' => 'baz' }
      attrs = {}
      attr_name, attr_value = Asciidoctor::Parser.store_attribute name, value, doc, attrs
      assert_equal name.sub('!', ''), attr_name
      assert_nil attr_value
      refute attrs.key?(:attribute_entries)
    end
  end

  test 'parse style attribute with id and role' do
    attributes = { 1 => 'style#id.role' }
    style = Asciidoctor::Parser.parse_style_attribute(attributes)
    assert_equal 'style', style
    assert_equal 'style', attributes['style']
    assert_equal 'id', attributes['id']
    assert_equal 'role', attributes['role']
    assert_equal 'style#id.role', attributes[1]
  end

  test 'parse style attribute with style, role, id and option' do
    attributes = { 1 => 'style.role#id%fragment' }
    style = Asciidoctor::Parser.parse_style_attribute(attributes)
    assert_equal 'style', style
    assert_equal 'style', attributes['style']
    assert_equal 'id', attributes['id']
    assert_equal 'role', attributes['role']
    assert_equal '', attributes['fragment-option']
    assert_equal 'style.role#id%fragment', attributes[1]
    refute attributes.key? 'options'
  end

  test 'parse style attribute with style, id and multiple roles' do
    attributes = { 1 => 'style#id.role1.role2' }
    style = Asciidoctor::Parser.parse_style_attribute(attributes)
    assert_equal 'style', style
    assert_equal 'style', attributes['style']
    assert_equal 'id', attributes['id']
    assert_equal 'role1 role2', attributes['role']
    assert_equal 'style#id.role1.role2', attributes[1]
  end

  test 'parse style attribute with style, multiple roles and id' do
    attributes = { 1 => 'style.role1.role2#id' }
    style = Asciidoctor::Parser.parse_style_attribute(attributes)
    assert_equal 'style', style
    assert_equal 'style', attributes['style']
    assert_equal 'id', attributes['id']
    assert_equal 'role1 role2', attributes['role']
    assert_equal 'style.role1.role2#id', attributes[1]
  end

  test 'parse style attribute with positional and original style' do
    attributes = { 1 => 'new_style', 'style' => 'original_style' }
    style = Asciidoctor::Parser.parse_style_attribute(attributes)
    assert_equal 'new_style', style
    assert_equal 'new_style', attributes['style']
    assert_equal 'new_style', attributes[1]
  end

  test 'parse style attribute with id and role only' do
    attributes = { 1 => '#id.role' }
    style = Asciidoctor::Parser.parse_style_attribute(attributes)
    assert_nil style
    assert_equal 'id', attributes['id']
    assert_equal 'role', attributes['role']
    assert_equal '#id.role', attributes[1]
  end

  test 'parse empty style attribute' do
    attributes = { 1 => nil }
    style = Asciidoctor::Parser.parse_style_attribute(attributes)
    assert_nil style
    assert_nil attributes['id']
    assert_nil attributes['role']
    assert_nil attributes[1]
  end

  test 'parse style attribute with option should preserve existing options' do
    attributes = { 1 => '%header', 'footer-option' => '' }
    style = Asciidoctor::Parser.parse_style_attribute(attributes)
    assert_nil style
    assert_equal '', attributes['header-option']
    assert_equal '', attributes['footer-option']
  end

  test "parse author first" do
    metadata, _ = parse_header_metadata 'Stuart'
    assert_equal 5, metadata.size
    assert_equal 1, metadata['authorcount']
    assert_equal metadata['author'], metadata['authors']
    assert_equal 'Stuart', metadata['firstname']
    assert_equal 'S', metadata['authorinitials']
  end

  test "parse author first last" do
    metadata, _ = parse_header_metadata 'Yukihiro Matsumoto'
    assert_equal 6, metadata.size
    assert_equal 1, metadata['authorcount']
    assert_equal 'Yukihiro Matsumoto', metadata['author']
    assert_equal metadata['author'], metadata['authors']
    assert_equal 'Yukihiro', metadata['firstname']
    assert_equal 'Matsumoto', metadata['lastname']
    assert_equal 'YM', metadata['authorinitials']
  end

  test "parse author first middle last" do
    metadata, _ = parse_header_metadata 'David Heinemeier Hansson'
    assert_equal 7, metadata.size
    assert_equal 1, metadata['authorcount']
    assert_equal 'David Heinemeier Hansson', metadata['author']
    assert_equal metadata['author'], metadata['authors']
    assert_equal 'David', metadata['firstname']
    assert_equal 'Heinemeier', metadata['middlename']
    assert_equal 'Hansson', metadata['lastname']
    assert_equal 'DHH', metadata['authorinitials']
  end

  test "parse author first middle last email" do
    metadata, _ = parse_header_metadata 'David Heinemeier Hansson <rails@ruby-lang.org>'
    assert_equal 8, metadata.size
    assert_equal 1, metadata['authorcount']
    assert_equal 'David Heinemeier Hansson', metadata['author']
    assert_equal metadata['author'], metadata['authors']
    assert_equal 'David', metadata['firstname']
    assert_equal 'Heinemeier', metadata['middlename']
    assert_equal 'Hansson', metadata['lastname']
    assert_equal 'rails@ruby-lang.org', metadata['email']
    assert_equal 'DHH', metadata['authorinitials']
  end

  test "parse author first email" do
    metadata, _ = parse_header_metadata 'Stuart <founder@asciidoc.org>'
    assert_equal 6, metadata.size
    assert_equal 1, metadata['authorcount']
    assert_equal 'Stuart', metadata['author']
    assert_equal metadata['author'], metadata['authors']
    assert_equal 'Stuart', metadata['firstname']
    assert_equal 'founder@asciidoc.org', metadata['email']
    assert_equal 'S', metadata['authorinitials']
  end

  test "parse author first last email" do
    metadata, _ = parse_header_metadata 'Stuart Rackham <founder@asciidoc.org>'
    assert_equal 7, metadata.size
    assert_equal 1, metadata['authorcount']
    assert_equal 'Stuart Rackham', metadata['author']
    assert_equal metadata['author'], metadata['authors']
    assert_equal 'Stuart', metadata['firstname']
    assert_equal 'Rackham', metadata['lastname']
    assert_equal 'founder@asciidoc.org', metadata['email']
    assert_equal 'SR', metadata['authorinitials']
  end

  test "parse author with hyphen" do
    metadata, _ = parse_header_metadata 'Tim Berners-Lee <founder@www.org>'
    assert_equal 7, metadata.size
    assert_equal 1, metadata['authorcount']
    assert_equal 'Tim Berners-Lee', metadata['author']
    assert_equal metadata['author'], metadata['authors']
    assert_equal 'Tim', metadata['firstname']
    assert_equal 'Berners-Lee', metadata['lastname']
    assert_equal 'founder@www.org', metadata['email']
    assert_equal 'TB', metadata['authorinitials']
  end

  test "parse author with single quote" do
    metadata, _ = parse_header_metadata 'Stephen O\'Grady <founder@redmonk.com>'
    assert_equal 7, metadata.size
    assert_equal 1, metadata['authorcount']
    assert_equal 'Stephen O\'Grady', metadata['author']
    assert_equal metadata['author'], metadata['authors']
    assert_equal 'Stephen', metadata['firstname']
    assert_equal 'O\'Grady', metadata['lastname']
    assert_equal 'founder@redmonk.com', metadata['email']
    assert_equal 'SO', metadata['authorinitials']
  end

  test "parse author with dotted initial" do
    metadata, _ = parse_header_metadata 'Heiko W. Rupp <hwr@example.de>'
    assert_equal 8, metadata.size
    assert_equal 1, metadata['authorcount']
    assert_equal 'Heiko W. Rupp', metadata['author']
    assert_equal metadata['author'], metadata['authors']
    assert_equal 'Heiko', metadata['firstname']
    assert_equal 'W.', metadata['middlename']
    assert_equal 'Rupp', metadata['lastname']
    assert_equal 'hwr@example.de', metadata['email']
    assert_equal 'HWR', metadata['authorinitials']
  end

  test "parse author with underscore" do
    metadata, _ = parse_header_metadata 'Tim_E Fella'
    assert_equal 6, metadata.size
    assert_equal 1, metadata['authorcount']
    assert_equal 'Tim E Fella', metadata['author']
    assert_equal metadata['author'], metadata['authors']
    assert_equal 'Tim E', metadata['firstname']
    assert_equal 'Fella', metadata['lastname']
    assert_equal 'TF', metadata['authorinitials']
  end

  test 'parse author name with letters outside basic latin' do
    metadata, _ = parse_header_metadata 'Stéphane Brontë'
    assert_equal 6, metadata.size
    assert_equal 1, metadata['authorcount']
    assert_equal 'Stéphane Brontë', metadata['author']
    assert_equal metadata['author'], metadata['authors']
    assert_equal 'Stéphane', metadata['firstname']
    assert_equal 'Brontë', metadata['lastname']
    assert_equal 'SB', metadata['authorinitials']
  end

  test 'parse ideographic author names' do
    metadata, _ = parse_header_metadata '李 四 <si.li@example.com>'
    assert_equal 7, metadata.size
    assert_equal 1, metadata['authorcount']
    assert_equal '李 四', metadata['author']
    assert_equal metadata['author'], metadata['authors']
    assert_equal '李', metadata['firstname']
    assert_equal '四', metadata['lastname']
    assert_equal 'si.li@example.com', metadata['email']
    assert_equal '李四', metadata['authorinitials']
  end

  test "parse author condenses whitespace" do
    metadata, _ = parse_header_metadata 'Stuart       Rackham     <founder@asciidoc.org>'
    assert_equal 7, metadata.size
    assert_equal 1, metadata['authorcount']
    assert_equal 'Stuart Rackham', metadata['author']
    assert_equal metadata['author'], metadata['authors']
    assert_equal 'Stuart', metadata['firstname']
    assert_equal 'Rackham', metadata['lastname']
    assert_equal 'founder@asciidoc.org', metadata['email']
    assert_equal 'SR', metadata['authorinitials']
  end

  test "parse invalid author line becomes author" do
    metadata, _ = parse_header_metadata '   Stuart       Rackham, founder of AsciiDoc   <founder@asciidoc.org>'
    assert_equal 5, metadata.size
    assert_equal 1, metadata['authorcount']
    assert_equal 'Stuart Rackham, founder of AsciiDoc <founder@asciidoc.org>', metadata['author']
    assert_equal metadata['author'], metadata['authors']
    assert_equal 'Stuart Rackham, founder of AsciiDoc <founder@asciidoc.org>', metadata['firstname']
    assert_equal 'S', metadata['authorinitials']
  end

  test 'parse multiple authors' do
    metadata, _ = parse_header_metadata 'Doc Writer <doc.writer@asciidoc.org>; John Smith <john.smith@asciidoc.org>'
    assert_equal 2, metadata['authorcount']
    assert_equal 'Doc Writer, John Smith', metadata['authors']
    assert_equal 'Doc Writer', metadata['author']
    assert_equal 'Doc Writer', metadata['author_1']
    assert_equal 'John Smith', metadata['author_2']
  end

  test 'should not parse multiple authors if semi-colon is not followed by space' do
    metadata, _ = parse_header_metadata 'Joe Doe;Smith Johnson'
    assert_equal 1, metadata['authorcount']
  end

  test 'skips blank author entries in implicit author line' do
    metadata, _ = parse_header_metadata 'Doc Writer; ; John Smith <john.smith@asciidoc.org>;'
    assert_equal 2, metadata['authorcount']
    assert_equal 'Doc Writer', metadata['author_1']
    assert_equal 'John Smith', metadata['author_2']
  end

  test 'parse name with more than 3 parts in author attribute' do
    doc = empty_document
    parse_header_metadata ':author: Leroy  Harold  Scherer,  Jr.', doc
    assert_equal 'Leroy Harold Scherer, Jr.', doc.attributes['author']
    assert_equal 'Leroy', doc.attributes['firstname']
    assert_equal 'Harold', doc.attributes['middlename']
    assert_equal 'Scherer, Jr.', doc.attributes['lastname']
  end

  test 'use explicit authorinitials if set after implicit author line' do
    input = <<~'EOS'
    Jean-Claude Van Damme
    :authorinitials: JCVD
    EOS
    doc = empty_document
    parse_header_metadata input, doc
    assert_equal 'JCVD', doc.attributes['authorinitials']
  end

  test 'use explicit authorinitials if set after author attribute' do
    input = <<~'EOS'
    :author: Jean-Claude Van Damme
    :authorinitials: JCVD
    EOS
    doc = empty_document
    parse_header_metadata input, doc
    assert_equal 'JCVD', doc.attributes['authorinitials']
  end

  test 'use implicit authors if value of authors attribute matches computed value' do
    input = <<~'EOS'
    Doc Writer; Junior Writer
    :authors: Doc Writer, Junior Writer
    EOS
    doc = empty_document
    parse_header_metadata input, doc
    assert_equal 'Doc Writer, Junior Writer', doc.attributes['authors']
    assert_equal 'Doc Writer', doc.attributes['author_1']
    assert_equal 'Junior Writer', doc.attributes['author_2']
  end

  test 'replace implicit authors if value of authors attribute does not match computed value' do
    input = <<~'EOS'
    Doc Writer; Junior Writer
    :authors: Stuart Rackham; Dan Allen; Sarah White
    EOS
    doc = empty_document
    metadata, _ = parse_header_metadata input, doc
    assert_equal 3, metadata['authorcount']
    assert_equal 3, doc.attributes['authorcount']
    assert_equal 'Stuart Rackham, Dan Allen, Sarah White', doc.attributes['authors']
    assert_equal 'Stuart Rackham', doc.attributes['author_1']
    assert_equal 'Dan Allen', doc.attributes['author_2']
    assert_equal 'Sarah White', doc.attributes['author_3']
  end

  test 'sets authorcount to 0 if document has no authors' do
    input = ''
    doc = empty_document
    metadata, _ = parse_header_metadata input, doc
    assert_equal 0, doc.attributes['authorcount']
    assert_equal 0, metadata['authorcount']
  end

  test 'returns empty hash if document has no authors and invoked without document' do
    metadata, _ = parse_header_metadata ''
    assert_empty metadata
  end

  test 'does not drop name joiner when using multiple authors' do
    input = 'Kismet Chameleon; Lazarus het_Draeke'
    doc = empty_document
    parse_header_metadata input, doc
    assert_equal 2, doc.attributes['authorcount']
    assert_equal 'Kismet Chameleon, Lazarus het Draeke', doc.attributes['authors']
    assert_equal 'Kismet Chameleon', doc.attributes['author_1']
    assert_equal 'Lazarus het Draeke', doc.attributes['author_2']
    assert_equal 'het Draeke', doc.attributes['lastname_2']
  end

  test 'allows authors to be overridden using explicit author attributes' do
    input = <<~'EOS'
    Kismet Chameleon; Johnny Bravo; Lazarus het_Draeke
    :author_2: Danger Mouse
    EOS
    doc = empty_document
    parse_header_metadata input, doc
    assert_equal 3, doc.attributes['authorcount']
    assert_equal 'Kismet Chameleon, Danger Mouse, Lazarus het Draeke', doc.attributes['authors']
    assert_equal 'Kismet Chameleon', doc.attributes['author_1']
    assert_equal 'Danger Mouse', doc.attributes['author_2']
    assert_equal 'Lazarus het Draeke', doc.attributes['author_3']
    assert_equal 'het Draeke', doc.attributes['lastname_3']
  end

  test 'removes formatting before partitioning author defined using author attribute' do
    input = ':author: pass:n[http://example.org/community/team.html[Ze_**Project** team]]'

    doc = empty_document
    parse_header_metadata input, doc
    assert_equal 1, doc.attributes['authorcount']
    assert_equal '<a href="http://example.org/community/team.html">Ze <strong>Project</strong> team</a>', doc.attributes['authors']
    assert_equal 'Ze Project', doc.attributes['firstname']
    assert_equal 'team', doc.attributes['lastname']
  end

  test "parse rev number date remark" do
    input = <<~'EOS'
    Ryan Waldron
    v0.0.7, 2013-12-18: The first release you can stand on
    EOS
    metadata, _ = parse_header_metadata input
    assert_equal 9, metadata.size
    assert_equal '0.0.7', metadata['revnumber']
    assert_equal '2013-12-18', metadata['revdate']
    assert_equal 'The first release you can stand on', metadata['revremark']
  end

  test 'parse rev number, data, and remark as attribute references' do
    input = <<~'EOS'
    Author Name
    v{project-version}, {release-date}: {release-summary}
    EOS
    metadata, _ = parse_header_metadata input
    assert_equal 9, metadata.size
    assert_equal '{project-version}', metadata['revnumber']
    assert_equal '{release-date}', metadata['revdate']
    assert_equal '{release-summary}', metadata['revremark']
  end

  test 'should resolve attribute references in rev number, data, and remark' do
    input = <<~'EOS'
    = Document Title
    Author Name
    {project-version}, {release-date}: {release-summary}
    EOS
    doc = document_from_string input, attributes: {
      'project-version' => '1.0.1',
      'release-date' => '2018-05-15',
      'release-summary' => 'The one you can count on!',
    }
    assert_equal '1.0.1', (doc.attr 'revnumber')
    assert_equal '2018-05-15', (doc.attr 'revdate')
    assert_equal 'The one you can count on!', (doc.attr 'revremark')
  end

  test "parse rev date" do
    input = <<~'EOS'
    Ryan Waldron
    2013-12-18
    EOS
    metadata, _ = parse_header_metadata input
    assert_equal 7, metadata.size
    assert_equal '2013-12-18', metadata['revdate']
  end

  test 'parse rev number with trailing comma' do
    input = <<~'EOS'
    Stuart Rackham
    v8.6.8,
    EOS
    metadata, _ = parse_header_metadata input
    assert_equal 7, metadata.size
    assert_equal '8.6.8', metadata['revnumber']
    refute metadata.key?('revdate')
  end

  # Asciidoctor recognizes a standalone revision without a trailing comma
  test 'parse rev number' do
    input = <<~'EOS'
    Stuart Rackham
    v8.6.8
    EOS
    metadata, _ = parse_header_metadata input
    assert_equal 7, metadata.size
    assert_equal '8.6.8', metadata['revnumber']
    refute metadata.key?('revdate')
  end

  # while compliant w/ AsciiDoc, this is just sloppy parsing
  test "treats arbitrary text on rev line as revdate" do
    input = <<~'EOS'
    Ryan Waldron
    foobar
    EOS
    metadata, _ = parse_header_metadata input
    assert_equal 7, metadata.size
    assert_equal 'foobar', metadata['revdate']
  end

  test "parse rev date remark" do
    input = <<~'EOS'
    Ryan Waldron
    2013-12-18:  The first release you can stand on
    EOS
    metadata, _ = parse_header_metadata input
    assert_equal 8, metadata.size
    assert_equal '2013-12-18', metadata['revdate']
    assert_equal 'The first release you can stand on', metadata['revremark']
  end

  test "should not mistake attribute entry as rev remark" do
    input = <<~'EOS'
    Joe Cool
    :page-layout: post
    EOS
    metadata, _ = parse_header_metadata input
    refute_equal 'page-layout: post', metadata['revremark']
    refute metadata.key?('revdate')
  end

  test "parse rev remark only" do
    # NOTE cannot use single-quoted heredoc because of https://github.com/jruby/jruby/issues/4260
    input = <<~EOS
    Joe Cool
     :Must start revremark-only line with space
    EOS
    metadata, _ = parse_header_metadata input
    assert_equal 'Must start revremark-only line with space', metadata['revremark']
    refute metadata.key?('revdate')
  end

  test "skip line comments before author" do
    input = <<~'EOS'
    // Asciidoctor
    // release artist
    Ryan Waldron
    EOS
    metadata, _ = parse_header_metadata input
    assert_equal 6, metadata.size
    assert_equal 1, metadata['authorcount']
    assert_equal 'Ryan Waldron', metadata['author']
    assert_equal 'Ryan', metadata['firstname']
    assert_equal 'Waldron', metadata['lastname']
    assert_equal 'RW', metadata['authorinitials']
  end

  test "skip block comment before author" do
    input = <<~'EOS'
    ////
    Asciidoctor
    release artist
    ////
    Ryan Waldron
    EOS
    metadata, _ = parse_header_metadata input
    assert_equal 6, metadata.size
    assert_equal 1, metadata['authorcount']
    assert_equal 'Ryan Waldron', metadata['author']
    assert_equal 'Ryan', metadata['firstname']
    assert_equal 'Waldron', metadata['lastname']
    assert_equal 'RW', metadata['authorinitials']
  end

  test "skip block comment before rev" do
    input = <<~'EOS'
    Ryan Waldron
    ////
    Asciidoctor
    release info
    ////
    v0.0.7, 2013-12-18
    EOS
    metadata, _ = parse_header_metadata input
    assert_equal 8, metadata.size
    assert_equal 1, metadata['authorcount']
    assert_equal 'Ryan Waldron', metadata['author']
    assert_equal '0.0.7', metadata['revnumber']
    assert_equal '2013-12-18', metadata['revdate']
  end

  test 'break header at line with three forward slashes' do
    input = <<~'EOS'
    Joe Cool
    v1.0
    ///
    stuff
    EOS
    metadata, _ = parse_header_metadata input
    assert_equal 7, metadata.size
    assert_equal 1, metadata['authorcount']
    assert_equal 'Joe Cool', metadata['author']
    assert_equal '1.0', metadata['revnumber']
  end

  test 'attribute entry overrides generated author initials' do
    doc = empty_document
    metadata, _ = parse_header_metadata %(Stuart Rackham <founder@asciidoc.org>\n:Author Initials: SJR), doc
    assert_equal 'SR', metadata['authorinitials']
    assert_equal 'SJR', doc.attributes['authorinitials']
  end

  test 'adjust indentation to 0' do
    input = <<~EOS
    \x20   def names

    \x20     @name.split

    \x20   end
    EOS

    # NOTE cannot use single-quoted heredoc because of https://github.com/jruby/jruby/issues/4260
    expected = <<~EOS.chop
    def names

      @name.split

    end
    EOS

    lines = input.split ?\n
    Asciidoctor::Parser.adjust_indentation! lines
    assert_equal expected, (lines * ?\n)
  end

  test 'adjust indentation mixed with tabs and spaces to 0' do
    input = <<~EOS
        def names

    \t  @name.split

        end
    EOS

    expected = <<~EOS.chop
    def names

      @name.split

    end
    EOS

    lines = input.split ?\n
    Asciidoctor::Parser.adjust_indentation! lines, 0, 4
    assert_equal expected, (lines * ?\n)
  end

  test 'expands tabs to spaces' do
    input = <<~'EOS'
    Filesystem				Size	Used	Avail	Use%	Mounted on
    Filesystem              Size    Used    Avail   Use%    Mounted on
    devtmpfs				3.9G	   0	 3.9G	  0%	/dev
    /dev/mapper/fedora-root	 48G	 18G	  29G	 39%	/
    EOS

    expected = <<~'EOS'.chop
    Filesystem              Size    Used    Avail   Use%    Mounted on
    Filesystem              Size    Used    Avail   Use%    Mounted on
    devtmpfs                3.9G       0     3.9G     0%    /dev
    /dev/mapper/fedora-root  48G     18G      29G    39%    /
    EOS

    lines = input.split ?\n
    Asciidoctor::Parser.adjust_indentation! lines, 0, 4
    assert_equal expected, (lines * ?\n)
  end

  test 'adjust indentation to non-zero' do
    input = <<~EOS
    \x20   def names

    \x20     @name.split

    \x20   end
    EOS

    expected = <<~EOS.chop
    \x20 def names

    \x20   @name.split

    \x20 end
    EOS

    lines = input.split ?\n
    Asciidoctor::Parser.adjust_indentation! lines, 2
    assert_equal expected, (lines * ?\n)
  end

  test 'preserve block indent if indent is -1' do
    input = <<~EOS
    \x20   def names

    \x20     @name.split

    \x20   end
    EOS

    expected = input

    lines = input.lines
    Asciidoctor::Parser.adjust_indentation! lines, -1
    assert_equal expected, lines.join
  end

  test 'adjust indentation handles empty lines gracefully' do
    input = []
    expected = input

    lines = input.dup
    Asciidoctor::Parser.adjust_indentation! lines
    assert_equal expected, lines
  end

  test 'should warn if inline anchor is already in use' do
    input = <<~'EOS'
    [#in-use]
    A paragraph with an id.

    Another paragraph
    [[in-use]]that uses an id
    which is already in use.
    EOS

    using_memory_logger do |logger|
      document_from_string input
      assert_message logger, :WARN, '<stdin>: line 5: id assigned to anchor already in use: in-use', Hash
    end
  end
end
