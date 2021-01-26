defimpl Jason.Encoder, for: Crontab.CronExpression do
  @spec encode(Jason.Encoder.t(), Jason.Encoder.opts()) :: iodata
  def encode(value, opts) do
    binary = Crontab.CronExpression.Composer.compose(value)
    Jason.Encode.string(binary, opts)
  end
end
