describe Hamlit::Compiler do
  describe 'script' do
    it 'compiles hamlit script ast into assigning' do
      assert_compile(
        [:haml,
         :script,
         'link_to user_path do',
         [:static, 'user']],
        [:multi,
         [:code, "_hamlit_compiler0 = link_to user_path do"],
         [:static, "user"],
         [:escape, false, [:dynamic, "(_hamlit_compiler0).to_s"]]],
      )
    end

    it 'compiles multiple hamlit scripts' do
      assert_compile(
        [:multi,
         [:haml,
          :script,
          'link_to user_path do',
          [:static, 'user']],
         [:haml,
          :script,
          'link_to repo_path do',
          [:static, 'repo']]],
        [:multi,
         [:multi,
          [:code, "_hamlit_compiler0 = link_to user_path do"],
          [:static, "user"],
          [:escape, false, [:dynamic, "(_hamlit_compiler0).to_s"]]],
         [:multi,
          [:code, "_hamlit_compiler1 = link_to repo_path do"],
          [:static, "repo"],
          [:escape, false, [:dynamic, "(_hamlit_compiler1).to_s"]]]],
      )
    end
  end
end
