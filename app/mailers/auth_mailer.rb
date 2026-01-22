class AuthMailer < ApplicationMailer
  def magic_link(user)
    @user = user
    @magic_link_url = verify_magic_link_url(token: user.magic_login_token)

    mail(
      to: user.email,
      subject: "Your login link for Listailor ATS"
    )
  end
end
