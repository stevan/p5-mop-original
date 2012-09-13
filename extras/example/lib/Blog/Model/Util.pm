package Blog::Model::Util {
    use v5.16;
    use Fun;
    use JSON::XS ();

    # NOTE:
    # hack until doy fixes the Closure
    # prototype issue with Fun
    # - SL
    sub JSON { state $JSON = JSON::XS->new->pretty; $JSON; }

    fun encode_model ( $blog ) { JSON->encode( $blog->pack ) }
    fun decode_model ( $json ) { Blog::Model::Blog->new->unpack( JSON->decode( $json ) ) }
}

1;